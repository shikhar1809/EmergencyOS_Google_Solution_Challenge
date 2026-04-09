import { llm, voice } from '@livekit/agents';
import type { Room } from '@livekit/rtc-node';
import { z } from 'zod';

const BASE_INSTRUCTIONS = `You are LIFELINE COPILOT for EmergencyOS, a first-response safety app.
You speak by voice. Be concise, calm, and clear. No emojis, asterisks, or markdown.
You help users understand the current screen and what to do next.

CRITICAL MEDICAL PROTOCOLS YOU MUST KNOW:

CPR (Unresponsive, not breathing):
1. Call emergency services or ask someone to call.
2. Place heel of hand on center of chest (lower half of sternum).
3. Push hard, push fast: 5-6 cm depth, 100-120 compressions per minute.
4. After 30 compressions, give 2 rescue breaths (tilt head, lift chin, seal mouth).
5. Continue 30:2 ratio until help arrives or the person responds.

CHOKING (Conscious adult):
1. Ask "Are you choking?" If they nod, act immediately.
2. Give 5 back blows between shoulder blades with heel of hand.
3. If not cleared, give 5 abdominal thrusts (Heimlich): fist above navel, pull inward and upward.
4. Alternate back blows and thrusts until object is expelled or person becomes unconscious.
5. If unconscious, begin CPR and check mouth for visible object before each breath.

SEVERE BLEEDING:
1. Apply direct pressure with clean cloth or hands.
2. Keep pressing firmly — do not lift to check.
3. If blood soaks through, add more cloth on top.
4. Elevate the limb if possible.
5. For limb bleeding not controlled by pressure, apply tourniquet 5-7 cm above wound. Note the time.

BURNS:
1. Cool the burn under cool running water for at least 20 minutes.
2. Remove clothing and jewelry near burn unless stuck.
3. Cover with clean, non-fluffy material (cling film works well).
4. Do NOT apply ice, butter, or creams.
5. For chemical burns, flush with water for 20+ minutes while removing contaminated clothing.

HEART ATTACK SIGNS:
1. Chest pain, pressure, or squeezing lasting more than a few minutes.
2. Pain spreading to arms, jaw, neck, or back.
3. Shortness of breath, nausea, cold sweat.
4. Have the person sit down and rest in a comfortable position.
5. If they have prescribed nitroglycerin, help them take it.
6. If aspirin is available and they are not allergic, have them chew one regular aspirin.
7. Call emergency services immediately.

STROKE RECOGNITION (FAST):
F - Face drooping on one side
A - Arm weakness — ask them to raise both arms
S - Speech difficulty — slurred or unable to speak
T - Time to call emergency services immediately
Note the time symptoms started — this is critical for treatment decisions.

When guiding a user through any of these protocols:
- Speak each step clearly and wait for acknowledgment before proceeding.
- Adapt language to the user's apparent stress level.
- If the user asks to explain the page or what to do here, use the getAppPageContext tool first if you need the latest route summary.
- Never pretend you triggered SOS yourself; the app must confirm any SOS request.
- Remind them to call local emergency services (112 in India) when appropriate.`;

export function buildCopilotTools(opts: {
  room: Room;
  walkthrough: boolean;
  getPageContext: () => string;
}): NonNullable<voice.AgentOptions['tools']> {
  const getAppPageContext = llm.tool({
    description:
      'Returns the current app route, title, and digest text the user last sent. Use when they ask what screen they are on or to explain this page.',
    execute: async () => opts.getPageContext(),
  });

  const getMedicalProtocol = llm.tool({
    description:
      'Look up a specific emergency medical protocol by topic. Use when the user asks about a specific emergency situation like CPR, choking, bleeding, burns, heart attack, or stroke.',
    parameters: z.object({
      topic: z.string().describe('The emergency topic: cpr, choking, bleeding, burns, heart_attack, stroke, seizure, allergic_reaction, drowning, fracture'),
    }),
    execute: async ({ topic }) => {
      const protocols: Record<string, string> = {
        cpr: 'CPR Protocol: 1) Check responsiveness. 2) Call 112. 3) 30 chest compressions at 100-120/min, 5-6cm deep. 4) 2 rescue breaths. 5) Repeat 30:2 until help arrives. For infants: use 2 fingers, 4cm depth.',
        choking: 'Choking Protocol: 1) 5 back blows between shoulder blades. 2) 5 abdominal thrusts (Heimlich). 3) Alternate until clear. If unconscious: start CPR, check mouth before breaths.',
        bleeding: 'Bleeding Protocol: 1) Direct pressure with clean cloth. 2) Do not lift to check. 3) Add layers if soaked through. 4) Elevate limb. 5) Tourniquet if uncontrolled: 5-7cm above wound, note time.',
        burns: 'Burns Protocol: 1) Cool under running water 20+ minutes. 2) Remove clothing/jewelry unless stuck. 3) Cover with cling film or clean material. 4) No ice, butter, or creams. 5) Chemical: flush 20+ min.',
        heart_attack: 'Heart Attack Protocol: 1) Call 112. 2) Have person sit and rest. 3) Chew aspirin if available and not allergic. 4) Nitroglycerin if prescribed. 5) Be ready for CPR.',
        stroke: 'Stroke Protocol (FAST): F-Face drooping, A-Arm weakness, S-Speech difficulty, T-Time to call 112. Note symptom start time. Do not give food/water. Keep person comfortable.',
        seizure: 'Seizure Protocol: 1) Clear area of dangerous objects. 2) Do NOT restrain or put anything in mouth. 3) Cushion head. 4) Time the seizure. 5) Roll to recovery position after. 6) Call 112 if >5 minutes or first seizure.',
        allergic_reaction: 'Severe Allergic Reaction: 1) Call 112. 2) Use epinephrine auto-injector if available (mid-outer thigh). 3) Have person lie down with legs elevated unless breathing is difficult. 4) Second dose after 5-15 min if no improvement.',
        drowning: 'Drowning Protocol: 1) Get person out of water safely. 2) Call 112. 3) Check breathing. 4) If not breathing: 5 rescue breaths first, then CPR. 5) If breathing: recovery position. 6) Keep warm.',
        fracture: 'Fracture Protocol: 1) Do not move the injured area. 2) Immobilize with splint or padding. 3) Apply ice wrapped in cloth. 4) Elevate if possible. 5) For open fractures: cover wound, do not push bone back.',
      };
      return protocols[topic.toLowerCase()] ?? 'Protocol not found. Available: cpr, choking, bleeding, burns, heart_attack, stroke, seizure, allergic_reaction, drowning, fracture.';
    },
  });

  const tools: NonNullable<voice.AgentOptions['tools']> = {
    getAppPageContext,
    getMedicalProtocol,
  };

  if (opts.walkthrough) {
    tools.requestEmergencySos = llm.tool({
      description:
        'Request the app to open the SOS emergency flow. Only use when the user clearly wants emergency help. The user must confirm in the app.',
      parameters: z.object({
        reason: z.string().describe('Short reason for the SOS request'),
      }),
      execute: async ({ reason }) => {
        const payload = new TextEncoder().encode(
          JSON.stringify({
            type: 'request_sos',
            nonce: crypto.randomUUID(),
            reason,
          }),
        );
        const lp = opts.room.localParticipant;
        if (lp) {
          await lp.publishData(payload, { reliable: true, topic: 'copilot_action' });
        }
        return 'The app was notified. Ask the user to confirm SOS on screen if a dialog appears.';
      },
    });
  }

  return tools;
}

export class CopilotAgent extends voice.Agent {
  constructor(tools: NonNullable<voice.AgentOptions['tools']>) {
    super({
      instructions: BASE_INSTRUCTIONS,
      tools,
    });
  }
}
