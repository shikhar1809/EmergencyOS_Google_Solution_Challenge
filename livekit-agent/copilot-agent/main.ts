import {
  type JobContext,
  type JobProcess,
  ServerOptions,
  cli,
  defineAgent,
  voice,
} from '@livekit/agents';
import * as livekit from '@livekit/agents-plugin-livekit';
import * as silero from '@livekit/agents-plugin-silero';
import { BackgroundVoiceCancellation } from '@livekit/noise-cancellation-node';
import { RoomEvent } from '@livekit/rtc-node';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

import { CopilotAgent, buildCopilotTools } from './copilot_agent.js';

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
    proc.userData.vad = await silero.VAD.load();
  },
  entry: async (ctx: JobContext) => {
    const meta = parseMetadata((ctx.job as { metadata?: unknown }).metadata);
    const walkthrough =
      meta.walkthrough === true ||
      meta.walkthrough === 'true' ||
      String(meta.walkthrough ?? '') === 'true';

    let pageContext = `Route: unknown.\nTitle: unknown.\nDigest: none.\nWalkthrough: ${walkthrough}`;

    const applyContextPayload = (payload: Uint8Array) => {
      try {
        const text = new TextDecoder().decode(payload);
        const j = JSON.parse(text) as {
          route?: string;
          title?: string;
          digest?: string;
          walkthrough?: boolean;
        };
        pageContext = [
          `Route: ${j.route ?? 'unknown'}`,
          `Title: ${j.title ?? 'unknown'}`,
          `Digest: ${(j.digest ?? '').trim() || 'none'}`,
          `Walkthrough: ${String(j.walkthrough ?? walkthrough)}`,
        ].join('\n');
      } catch (_) {
        /* ignore malformed */
      }
    };

    const tools = buildCopilotTools({
      room: ctx.room,
      walkthrough,
      getPageContext: () => pageContext,
    });

    const vad = ctx.proc.userData.vad as silero.VAD;

    const session = new voice.AgentSession({
      vad,
      stt: 'deepgram/nova-3:multi',
      llm: 'google/gemini-2.5-flash',
      tts: 'cartesia/sonic-3:9626c31c-bec5-4cca-baa8-f8ba9e84c8bc',
      turnHandling: {
        turnDetection: new livekit.turnDetector.MultilingualModel(),
      },
    });

    await session.start({
      agent: new CopilotAgent(tools),
      room: ctx.room,
      inputOptions: {
        noiseCancellation: BackgroundVoiceCancellation(),
      },
    });

    await ctx.connect();

    ctx.room.on(RoomEvent.DataReceived, (payload, _participant, _kind, topic) => {
      if (topic === 'copilot_context') {
        applyContextPayload(payload);
      }
    });

    session.generateReply({
      instructions:
        'Briefly greet the user as LIFELINE Copilot. Offer to explain the current screen or help in an emergency.',
    });
  },
});

cli.runApp(
  new ServerOptions({
    agent: fileURLToPath(import.meta.url),
    agentName: 'copilot',
  }),
);
