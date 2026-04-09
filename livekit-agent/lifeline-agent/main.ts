import {
  type JobContext,
  type JobProcess,
  ServerOptions,
  cli,
  defineAgent,
  voice,
} from '@livekit/agents';
import * as openai from '@livekit/agents-plugin-openai';
import { BackgroundVoiceCancellation } from '@livekit/noise-cancellation-node';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

import { LifelineAgent } from './agent';

dotenv.config({ path: '.env.local' });

function parseMetadata(raw: unknown): Record<string, unknown> {
  if (!raw) return {};
  if (typeof raw === 'object') return raw as Record<string, unknown>;
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw) as Record<string, unknown>;
    } catch (_) {
      return {};
    }
  }
  return {};
}

export default defineAgent({
  prewarm: async (proc: JobProcess) => {
    // The realtime model pipeline does not require STT/VAD prewarm,
    // but keeping this hook consistent avoids later refactors.
    proc.userData = proc.userData ?? {};
  },
  entry: async (ctx: JobContext) => {
    const session = new voice.AgentSession({
      llm: new openai.realtime.RealtimeModel({
        // Change voice if you prefer a different TTS persona.
        voice: 'coral',
      }),
    });

    await session.start({
      agent: new LifelineAgent(),
      room: ctx.room,
      inputOptions: {
        // Best effort noise cancellation for telephony/SIP.
        noiseCancellation: BackgroundVoiceCancellation(),
      },
    });

    await ctx.connect();

    const meta = parseMetadata((ctx.job as any)?.metadata);
    const importantComms =
      (meta.importantComms as string?) ??
      (meta.important_comms as string?) ??
      (meta.text as string?);

    if (importantComms && importantComms.trim()) {
      const handle = session.generateReply({
        instructions:
          'Read the following message clearly and EXACTLY as written, with no extra words:\n\n' +
          importantComms.trim(),
      });
      await handle.waitForPlayout();
    }

    // End the job after speaking (job-driven, no conversation loop).
    await session.shutdown();
  },
});

cli.runApp(
  new ServerOptions({
    agent: fileURLToPath(import.meta.url),
    agentName: 'lifeline',
  }),
);

