import { voice } from '@livekit/agents';

export class LifelineAgent extends voice.Agent {
  constructor() {
    super({
      // Job metadata provides the exact text to read. Avoid adding anything else.
      instructions:
        'You are LIFELINE for emergency response. When you receive instructions to read a message, speak it clearly and verbatim. Do not add apologies, questions, or extra words.',
    });
  }
}

