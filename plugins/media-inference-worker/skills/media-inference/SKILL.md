---
name: media-inference
description: Generate images and videos from text prompts using the Higgsfield AI platform. Use when the user wants to create media assets via text-to-image or text-to-video models.
---

# Media Inference

Generate images and videos from text prompts using the Higgsfield AI platform API.

## Prerequisites

- **Python 3**: With `requests` installed (`pip install requests`)
- **API credentials**: Environment variables `HF_API_KEY_ID` and `HF_API_KEY_SECRET` must be set, or stored in a `.env` file alongside the script

## Available models

### Text-to-image

| Model              | Endpoint                                    |
| ------------------- | ------------------------------------------- |
| qwen-image-3        | `/alibaba/qwen-image-3/text-to-image`       |
| nano-banana-2-lite   | `/nano-banana-2/lite/text-to-image`          |
| gpt-image-2          | `/openai/gpt-image-2`                        |

### Text-to-video

| Model          | Endpoint                                        |
| --------------- | ----------------------------------------------- |
| minimax-h3      | `/minimax/h3/text-to-video`                      |
| ltx-2.5-pro     | `/lightricks/ltx-2.5/text-to-video/pro`          |
| kling-3.0       | `/kling-video/v3.0/std/text-to-video`             |
| veo-3.1-fast    | `/veo3.1/fast/text-to-video`                      |

## Authentication

Build the `Authorization` header from two environment variables:

```
Authorization: Key <HF_API_KEY_ID>:<HF_API_KEY_SECRET>
```

Load credentials from a `.env` file (key=value, one per line) or export them in the shell.

## Workflow

### 1. Submit a generation request

POST to the base URL plus the model endpoint with a JSON body containing the prompt.

```bash
curl https://platform.higgsfield.ai<endpoint> \
  -H "Authorization: Key ${HF_API_KEY_ID}:${HF_API_KEY_SECRET}" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"<user prompt>"}'
```

The response is a job object:

```json
{
  "status": "queued",
  "request_id": "...",
  "status_url": "https://platform.higgsfield.ai/requests/.../status",
  "cancel_url": "https://platform.higgsfield.ai/requests/.../cancel"
}
```

### 2. Poll for completion

GET `status_url` with the same authorization header. Use exponential backoff starting at 2 seconds, capping at 10 seconds.

Terminal statuses: `completed`, `failed`, `nsfw`, `canceled`.

### 3. Retrieve results

- **Images**: `result["images"][0]["url"]`
- **Videos**: `result["video"]["url"]`

On failure, check `result["error"]` for details.

## Python usage

```bash
pip install requests
python generate.py <model-name> "<prompt>"
```

Example:

```bash
python generate.py qwen-image-3 "Editorial portrait, hard flash, 35mm grain"
python generate.py minimax-h3 "A silver coupe driving through rain at night"
python generate.py ltx-2.5-pro "Handheld shot following a runner through an empty station"
```

## Implementation notes

- All models accept a `prompt` field in the JSON body.
- The API is asynchronous — every request returns a job that must be polled.
- Use `cancel_url` with the same auth header to cancel an in-progress job.
- Poll with jitter to avoid thundering-herd issues on concurrent requests.
