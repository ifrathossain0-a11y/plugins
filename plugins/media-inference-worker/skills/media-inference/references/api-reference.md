# Higgsfield AI Platform API Reference

## Base URL

```
https://platform.higgsfield.ai
```

## Authentication

All requests require the header:

```
Authorization: Key <key_id>:<secret>
```

Where `key_id` and `secret` come from `HF_API_KEY_ID` and `HF_API_KEY_SECRET` environment variables.

## Endpoints

### Text-to-image

```
POST /alibaba/qwen-image-3/text-to-image
POST /nano-banana-2/lite/text-to-image
POST /openai/gpt-image-2
```

### Text-to-video

```
POST /minimax/h3/text-to-video
POST /lightricks/ltx-2.5/text-to-video/pro
POST /kling-video/v3.0/std/text-to-video
POST /veo3.1/fast/text-to-video
```

## Request body

```json
{
  "prompt": "Description of the image or video to generate"
}
```

Content-Type: `application/json`

## Job response

Every generation endpoint returns a job:

```json
{
  "status": "queued",
  "request_id": "abc123",
  "status_url": "https://platform.higgsfield.ai/requests/abc123/status",
  "cancel_url": "https://platform.higgsfield.ai/requests/abc123/cancel"
}
```

## Polling

`GET <status_url>` with the same `Authorization` header.

### Status values

| Status      | Terminal | Meaning                        |
| ----------- | -------- | ------------------------------ |
| `queued`    | No       | Waiting in queue               |
| `processing`| No      | Generation in progress         |
| `completed` | Yes      | Finished successfully          |
| `failed`    | Yes      | Generation failed              |
| `nsfw`      | Yes      | Blocked by content filter      |
| `canceled`  | Yes      | Canceled via cancel endpoint   |

### Completed response — image

```json
{
  "status": "completed",
  "images": [
    { "url": "https://..." }
  ]
}
```

### Completed response — video

```json
{
  "status": "completed",
  "video": {
    "url": "https://..."
  }
}
```

### Failed response

```json
{
  "status": "failed",
  "error": "Description of what went wrong"
}
```

## Cancellation

`POST <cancel_url>` with the same `Authorization` header to cancel a queued or in-progress job.

## Polling strategy

Use exponential backoff starting at 2 seconds with a cap at 10 seconds. Add random jitter (up to 0.5 seconds) to each delay to reduce contention.
