# AWS Setup for Live Strands and Bedrock Mode

Do not paste AWS secrets into chat. Put them in a local `.env` file or your shell.

## Fastest Path for Hackathon Demo

1. Sign in to the AWS Console.
2. Open Amazon Bedrock.
3. Choose a region. Your screenshot shows `us-east-2`, United States Ohio, so use `us-east-2`.
4. Open Model access or Model catalog.
5. Choose an Anthropic Claude Sonnet 4.5 model.
6. Submit the Anthropic use case form if AWS asks for it.
7. Wait until access is granted.
8. Create a Bedrock API key, or configure normal AWS credentials.
9. Put the values in `backend/.env`.
10. Run `make runtime` to check readiness.
11. Run live mode with `CURIO_DEMO_MODE=false make run-strands`.

## Option A Bedrock API Key

Use this for quick exploration and demos.

```bash
AWS_BEARER_TOKEN_BEDROCK=your_bedrock_api_key
AWS_REGION=us-east-2
CURIO_DEMO_MODE=false
CURIO_BEDROCK_MODEL_ID=global.anthropic.claude-sonnet-4-5-20250929-v1:0
```

## Option B AWS Access Key

Use an IAM user or role with Bedrock invoke permissions.

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=... # only if temporary credentials include it
AWS_REGION=us-east-2
CURIO_DEMO_MODE=false
CURIO_BEDROCK_MODEL_ID=global.anthropic.claude-sonnet-4-5-20250929-v1:0
```

## Minimum Permissions for Runtime

The backend needs permission to call Bedrock Runtime:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

For stronger production security, restrict `Resource` to the exact model or inference profile ARN.

## Check

```bash
. .venv311/bin/activate
make runtime
```

You want:

```text
strands_installed: true
bedrock_model_importable: true
credentials_discoverable: true
demo_mode: false
```
