import { EC2Client, RunInstancesCommand, DescribeInstancesCommand } from "@aws-sdk/client-ec2";
import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";
import { createAppAuth } from "@octokit/auth-app";
import { Octokit } from "@octokit/core";

const ec2Client = new EC2Client();
const secretsClient = new SecretsManagerClient();

// --- CONSTANTS ---
const LAMBDA_TIMEOUT_BUFFER_MS = 10000;
const WATCHDOG_STARTUP_TIMEOUT = 600;
const WATCHDOG_IDLE_LIMIT = 120;
const SPOT_RETRY_ERRORS = [
    'InsufficientInstanceCapacity',
    'InsufficientCapacity',
    'SpotMaxPriceTooLow',
    'MaxSpotInstanceCountExceeded',
];

// --- STRUCTURED LOGGER ---
let logContext = {};
const log = (level, message, data = {}) => {
    console.log(JSON.stringify({
        level,
        message,
        timestamp: new Date().toISOString(),
        ...logContext,
        ...data,
    }));
};

// --- USERDATA GENERATOR ---
// Dependencies are pre-installed in the AMI — only register and start the runner
const getUserDataScript = (repoUrl, token, runId, extraLabels) => {
    // Strip spaces around commas in labels
    const labelList = extraLabels
        ? `${extraLabels},run-${runId}`.split(',').map(l => l.trim()).join(',')
        : `run-${runId}`;

    return `#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

RUNNER_USER="ubuntu"
RUNNER_DIR="/home/ubuntu/actions-runner"
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 1. SETUP GITHUB RUNNER
mkdir -p $RUNNER_DIR && cd $RUNNER_DIR

# Only download the runner if not already pre-installed in the AMI
if [ ! -f "$RUNNER_DIR/config.sh" ]; then
  latest_version=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\\1/')

  # Download with retry and archive validation
  for i in 1 2 3; do
    curl -o runner.tar.gz -L --retry 3 --retry-delay 5 \\
      https://github.com/actions/runner/releases/download/v$latest_version/actions-runner-linux-x64-$latest_version.tar.gz
    tar tzf runner.tar.gz > /dev/null 2>&1 && break
    echo "Download attempt $i failed, retrying..."
    rm -f runner.tar.gz
    sleep 10
  done

  tar xzf ./runner.tar.gz
  rm -f runner.tar.gz
else
  echo "Runner binary already present in AMI, skipping download"
fi

# 2. ENVIRONMENT
cat <<EOT > .path
/usr/local/bin
/usr/bin
/bin
/usr/sbin
/sbin
EOT

cat <<EOT > .env
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOT

chown -R $RUNNER_USER:$RUNNER_USER $RUNNER_DIR

# 3. REGISTER AND START
sudo -u $RUNNER_USER -E ./config.sh --url "${repoUrl}" --token "${token}" --labels "${labelList}" --unattended --replace
sudo -u $RUNNER_USER -E ./run.sh &

# 4. WATCHDOG — shut down instance when job is done or idle too long
timeout ${WATCHDOG_STARTUP_TIMEOUT}s bash -c 'until pgrep -x "Runner.Worker" > /dev/null; do sleep 5; done' || shutdown -h now

IDLE_COUNT=0
while [ $IDLE_COUNT -lt ${WATCHDOG_IDLE_LIMIT} ]; do
  if pgrep -x "Runner.Worker" > /dev/null; then
    IDLE_COUNT=0
  else
    IDLE_COUNT=$((IDLE_COUNT + 10))
  fi
  sleep 10
done

shutdown -h now
`;
};

// --- PARSE EVENT BODY ---
// Handles SQS (Records), API Gateway (string body), and direct invocation (object)
const parseEventBody = (event) => {
    const rawBody = event.Records ? event.Records[0].body : event.body ?? event;
    return typeof rawBody === 'string' ? JSON.parse(rawBody) : rawBody;
};

// --- VALIDATE REQUIRED FIELDS ---
const validateFields = ({ jobId, runId, repoUrl, owner, repo }) => {
    const missing = [];
    if (!jobId)   missing.push('jobId');
    if (!runId)   missing.push('runId');
    if (!repoUrl) missing.push('repoUrl');
    if (!owner)   missing.push('owner');
    if (!repo)    missing.push('repo');
    return missing;
};

// --- CHECK FOR EXISTING RUNNER ---
const hasExistingRunner = async (jobId) => {
    const response = await ec2Client.send(new DescribeInstancesCommand({
        Filters: [
            { Name: 'tag:GH_Job_ID', Values: [jobId] },
            { Name: 'instance-state-name', Values: ['pending', 'running'] },
        ],
    }));
    return (response.Reservations?.length ?? 0) > 0;
};

// --- FETCH GITHUB REGISTRATION TOKEN ---
const getRegistrationToken = async (owner, repo) => {
    const secretResponse = await secretsClient.send(
        new GetSecretValueCommand({ SecretId: process.env.SECRET_NAME })
    );
    const secrets = JSON.parse(secretResponse.SecretString);

    const octokit = new Octokit({
        authStrategy: createAppAuth,
        auth: {
            appId:          secrets.GH_APP_ID,
            privateKey:     secrets.GH_PRIVATE_KEY,
            installationId: secrets.GH_INSTALL_ID,
        },
    });

    const { data } = await octokit.request(
        'POST /repos/{owner}/{repo}/actions/runners/registration-token',
        { owner, repo }
    );

    if (!data.token) {
        throw new Error("GitHub API returned empty registration token");
    }

    return data.token;
};

// --- BUILD EC2 LAUNCH PARAMS ---
const buildLaunchParams = ({ jobId, runId, repoUrl, token, selectedSubnet }) => {
    // Token is embedded in UserData — never log it separately
    const userData = Buffer.from(
        getUserDataScript(repoUrl, token, runId, process.env.GH_LABELS)
    ).toString('base64');

return {
    LaunchTemplate: {
        LaunchTemplateName: process.env.LT_NAME,
        Version: '$Latest',
    },
    MinCount: 1,
    MaxCount: 1,
    ClientToken: `job-${jobId}`,
    InstanceInitiatedShutdownBehavior: 'terminate',
    NetworkInterfaces: [{
        DeviceIndex: 0,
        SubnetId: selectedSubnet,
        Groups: [process.env.SG_ID],
        AssociatePublicIpAddress: false,
    }],
    UserData: userData,
    TagSpecifications: [{
        ResourceType: "instance",
        Tags: [
            { Key: "Name",      Value: `Runner-Job-${jobId}` },
            { Key: "GH_Job_ID", Value: jobId },
            { Key: "Team",      Value: "ap13" },
            { Key: "ManagedBy", Value: "GitHub-Runner-Manager" },
        ],
    }],
};
};

// --- LAUNCH SPOT WITH ON-DEMAND FALLBACK ---
const launchInstance = async (baseParams, typeList) => {
    // Attempt spot launch across all instance types
    for (const instanceType of typeList) {
        try {
            await ec2Client.send(new RunInstancesCommand({
                ...baseParams,
                InstanceType: instanceType,
                InstanceMarketOptions: { MarketType: 'spot' },
            }));
            log('INFO', `Spot instance launched`, { instanceType });
            return { type: 'spot', instanceType };
        } catch (error) {
            if (SPOT_RETRY_ERRORS.includes(error.name)) {
                log('WARN', `Spot capacity unavailable, trying next type`, { instanceType, error: error.name });
                continue;
            }
            throw error;
        }
    }

    // All spot attempts failed — fall back to on-demand
    log('WARN', 'All spot attempts failed, falling back to on-demand');
    const onDemandType = process.env.ON_DEMAND_INSTANCE_TYPE || typeList[0];
    await ec2Client.send(new RunInstancesCommand({
        ...baseParams,
        InstanceType: onDemandType,
        // No InstanceMarketOptions = on-demand
    }));
    log('INFO', `On-demand instance launched`, { instanceType: onDemandType });
    return { type: 'on-demand', instanceType: onDemandType };
};

// --- MAIN HANDLER ---
export const handler = async (event, context) => {
    context.callbackWaitsForEmptyEventLoop = false;

    if (context.getRemainingTimeInMillis() < LAMBDA_TIMEOUT_BUFFER_MS) {
        log('ERROR', 'Lambda timeout imminent, aborting before execution');
        return { statusCode: 500, body: 'Lambda timeout' };
    }

    const messageId = event.Records?.[0]?.messageId;
    if (messageId) log('INFO', 'Processing SQS message', { messageId });

    // --- PARSE BODY ---
    let body;
    try {
        body = parseEventBody(event);
    } catch (e) {
        log('ERROR', 'Failed to parse event body', { error: e.message });
        return { statusCode: 400, body: 'Invalid JSON body' };
    }

    // --- EXTRACT FIELDS ---
    const jobId   = body.workflow_job?.id?.toString();
    const runId   = body.workflow_job?.run_id?.toString();
    const repoUrl = body.repository?.html_url;
    const owner   = body.repository?.owner?.login;
    const repo    = body.repository?.name;

    logContext = { jobId, runId, owner, repo };

    // --- VALIDATE FIELDS ---
    const missingFields = validateFields({ jobId, runId, repoUrl, owner, repo });
    if (missingFields.length > 0) {
        log('ERROR', 'Missing required webhook fields', { missingFields });
        return { statusCode: 400, body: `Missing fields: ${missingFields.join(', ')}` };
    }

    // --- FILTER: only handle queued self-hosted jobs ---
    if (body.action !== 'queued') {
        log('INFO', 'Ignoring non-queued action', { action: body.action });
        return { statusCode: 200, body: 'Ignore: Action not queued' };
    }

    const jobLabels = body.workflow_job?.labels || [];
    const isSelfHosted = jobLabels
        .map(l => (typeof l === 'string' ? l : l.name).toLowerCase())
        .includes('self-hosted');

    if (!isSelfHosted) {
        log('INFO', 'Ignoring non-self-hosted job', { labels: jobLabels });
        return { statusCode: 200, body: 'Ignore: Not a self-hosted job' };
    }

    try {
        // --- CONCURRENCY CHECK ---
        if (await hasExistingRunner(jobId)) {
            log('INFO', 'Runner already exists for this job, skipping');
            return { statusCode: 200, body: 'Job already has a runner' };
        }

        // --- GITHUB TOKEN ---
        const token = await getRegistrationToken(owner, repo);
        log('INFO', 'GitHub registration token obtained');

        // --- SUBNET SELECTION ---
        const subnets = (process.env.SUBNET_IDS || '').split(',').filter(Boolean);
        if (subnets.length === 0) throw new Error('SUBNET_IDS environment variable is not set');
        const selectedSubnet = subnets[parseInt(jobId) % subnets.length];

        // --- BUILD PARAMS ---
        const typeList = (process.env.INSTANCE_TYPES || 't3.micro').split(',').filter(Boolean);
        const baseParams = buildLaunchParams({ jobId, runId, repoUrl, token, selectedSubnet });

        // --- LAUNCH ---
        const result = await launchInstance(baseParams, typeList);

        log('INFO', 'Runner launched successfully', {
            launchType:   result.type,
            instanceType: result.instanceType,
            subnet:       selectedSubnet,
        });

        return {
            statusCode: 200,
            body: JSON.stringify({
                message:      `Runner launched for job ${jobId}`,
                launchType:   result.type,
                instanceType: result.instanceType,
            }),
        };

    } catch (err) {
        log('ERROR', 'Critical failure launching runner', { error: err.message, stack: err.stack });
        return { statusCode: 500, body: err.message };
    }
};
