// backend/src/routes/compatibility.js
// Mantra Feature 2: Compatibility DNA (7 Dimensions)
'use strict';

module.exports = async function compatibilityRoutes(fastify) {
  // Dimension definitions and evaluation helpers
  const DIMENSIONS = [
    'communication',
    'relationship_intentions',
    'core_values',
    'lifestyle',
    'emotional_readiness',
    'conflict_resolution',
    'shared_interests'
  ];

  function calculateDimensionAlignment(myAns, theirAns) {
    if (!myAns || !theirAns) {
      return { score: null, status: 'incomplete', explanation: 'Awaiting answers from one or both partners' };
    }

    const results = {};
    let totalScore = 0;
    let countedDimensions = 0;

    // 1. Communication
    if (myAns.communication && theirAns.communication) {
      const myPace = myAns.communication.pace; // 'thoughtful_daily' | 'constant_updates' | 'slow_evenings'
      const theirPace = theirAns.communication.pace;
      const myMedium = myAns.communication.preferred_medium; // 'text' | 'voice_notes' | 'calls'
      const theirMedium = theirAns.communication.preferred_medium;

      let commScore = 60;
      let reasons = [];
      if (myPace === theirPace) {
        commScore += 25;
        reasons.push(`Both prefer a ${myPace.replace('_', ' ')} rhythm`);
      } else {
        reasons.push(`Different conversation paces (${myPace.replace('_', ' ')} vs ${theirPace.replace('_', ' ')})`);
      }

      if (myMedium === theirMedium) {
        commScore += 15;
        reasons.push(`Mutual affinity for ${myMedium.replace('_', ' ')}`);
      }

      results.communication = {
        dimension: 'Communication Preferences',
        score: Math.min(commScore, 100),
        insight: reasons.join('. ') + '.',
        contributing_factors: ['Pace of conversation', 'Preferred medium'],
      };
      totalScore += results.communication.score;
      countedDimensions++;
    }

    // 2. Relationship Intentions
    if (myAns.relationship_intentions && theirAns.relationship_intentions) {
      const myGoal = myAns.relationship_intentions.primary_goal;
      const theirGoal = theirAns.relationship_intentions.primary_goal;
      const myPace = myAns.relationship_intentions.pacing;
      const theirPace = theirAns.relationship_intentions.pacing;

      let goalScore = 50;
      let reasons = [];
      if (myGoal === theirGoal) {
        goalScore += 30;
        reasons.push(`Both are mindfully seeking ${myGoal.replace('_', ' ')}`);
      } else {
        reasons.push(`Complementary perspectives on connection goals`);
      }

      if (myPace === theirPace) {
        goalScore += 20;
        reasons.push(`Harmonious approach to relationship pacing`);
      }

      results.relationship_intentions = {
        dimension: 'Relationship Intentions',
        score: Math.min(goalScore, 100),
        insight: reasons.join('. ') + '.',
        contributing_factors: ['Primary relationship goal', 'Approach to pacing'],
      };
      totalScore += results.relationship_intentions.score;
      countedDimensions++;
    }

    // 3. Core Values
    if (myAns.core_values && theirAns.core_values) {
      const myVals = new Set(Array.isArray(myAns.core_values) ? myAns.core_values : []);
      const theirVals = new Set(Array.isArray(theirAns.core_values) ? theirAns.core_values : []);
      const shared = [...myVals].filter(v => theirVals.has(v));
      const union = new Set([...myVals, ...theirVals]);

      const overlapPct = union.size > 0 ? Math.round((shared.length / union.size) * 100) : 60;
      const score = Math.max(50, Math.min(overlapPct + 30, 98));

      results.core_values = {
        dimension: 'Core Values',
        score,
        insight: shared.length > 0
          ? `Shared foundational values in: ${shared.slice(0, 3).join(', ')}.`
          : 'Diverse personal values that bring distinct perspectives to discussions.',
        shared_values: shared,
        contributing_factors: ['Self-selected priority ethical & personal values'],
      };
      totalScore += score;
      countedDimensions++;
    }

    // 4. Lifestyle Preferences
    if (myAns.lifestyle && theirAns.lifestyle) {
      const myRhythm = myAns.lifestyle.daily_rhythm; // 'morning' | 'night_owl' | 'balanced'
      const theirRhythm = theirAns.lifestyle.daily_rhythm;
      const mySocial = myAns.lifestyle.social_energy; // 'introvert' | 'extrovert' | 'ambivert'
      const theirSocial = theirAns.lifestyle.social_energy;

      let lifeScore = 65;
      let reasons = [];
      if (myRhythm === theirRhythm) {
        lifeScore += 15;
        reasons.push(`Matching daily energy cycle (${myRhythm})`);
      } else {
        reasons.push(`Balanced schedules (${myRhythm} paired with ${theirRhythm})`);
      }

      if (mySocial === theirSocial) {
        lifeScore += 20;
        reasons.push(`Similar social energy (${mySocial})`);
      } else {
        lifeScore += 10;
        reasons.push(`Complementary social balance (${mySocial} and ${theirSocial})`);
      }

      results.lifestyle = {
        dimension: 'Lifestyle Preferences',
        score: Math.min(lifeScore, 100),
        insight: reasons.join('. ') + '.',
        contributing_factors: ['Daily circadian rhythm', 'Social recharging style'],
      };
      totalScore += results.lifestyle.score;
      countedDimensions++;
    }

    // 5. Emotional Availability & Readiness
    if (myAns.emotional_readiness && theirAns.emotional_readiness) {
      const myOpenness = myAns.emotional_readiness.openness;
      const theirOpenness = theirAns.emotional_readiness.openness;

      let readyScore = 70;
      let reasons = [];
      if (myOpenness === theirOpenness) {
        readyScore += 25;
        reasons.push(`Matched readiness for emotional vulnerability (${myOpenness.replace('_', ' ')})`);
      } else {
        readyScore += 10;
        reasons.push(`Varying paces in opening up emotionally, inviting patience`);
      }

      results.emotional_readiness = {
        dimension: 'Emotional Readiness',
        score: Math.min(readyScore, 98),
        insight: reasons.join('. ') + '.',
        contributing_factors: ['Approach to vulnerability and emotional presence'],
      };
      totalScore += results.emotional_readiness.score;
      countedDimensions++;
    }

    // 6. Conflict Resolution Preferences
    if (myAns.conflict_resolution && theirAns.conflict_resolution) {
      const myStyle = myAns.conflict_resolution.style; // 'cool_off_first' | 'discuss_immediately' | 'written'
      const theirStyle = theirAns.conflict_resolution.style;

      let conflictScore = 60;
      let reasons = [];
      if (myStyle === theirStyle) {
        conflictScore += 35;
        reasons.push(`Aligned disagreement approach: both prefer to ${myStyle.replace('_', ' ')}`);
      } else {
        conflictScore += 15;
        reasons.push(`Different styles during tension (${myStyle.replace('_', ' ')} vs ${theirStyle.replace('_', ' ')}) requiring conscious communication`);
      }

      results.conflict_resolution = {
        dimension: 'Conflict Resolution',
        score: Math.min(conflictScore, 98),
        insight: reasons.join('. ') + '.',
        contributing_factors: ['Preferred approach during disagreements and emotional tension'],
      };
      totalScore += results.conflict_resolution.score;
      countedDimensions++;
    }

    // 7. Shared Interests
    if (myAns.shared_interests && theirAns.shared_interests) {
      const myInt = new Set(Array.isArray(myAns.shared_interests) ? myAns.shared_interests : []);
      const theirInt = new Set(Array.isArray(theirAns.shared_interests) ? theirAns.shared_interests : []);
      const common = [...myInt].filter(i => theirInt.has(i));

      const score = Math.max(50, Math.min(50 + common.length * 10, 95));
      results.shared_interests = {
        dimension: 'Shared Passions & Interests',
        score,
        insight: common.length > 0
          ? `Mutual interests in: ${common.slice(0, 4).join(', ')}.`
          : 'Individual hobbies offering rich opportunities to explore new activities together.',
        common_interests: common,
        contributing_factors: ['Self-described hobbies, cultural tastes, and pastimes'],
      };
      totalScore += score;
      countedDimensions++;
    }

    const overallScore = countedDimensions > 0 ? Math.round(totalScore / countedDimensions) : 75;

    return {
      overall_alignment: overallScore,
      evaluated_dimensions_count: countedDimensions,
      dimensions: results,
      ethical_notice: 'These insights reflect self-reported communication and lifestyle preferences to foster empathetic understanding. They are not a psychological diagnosis or guarantee of relationship success.',
    };
  }

  // GET /compatibility — Get user's own compatibility profile
  fastify.get('/', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;

    const result = await fastify.db.query(`
      SELECT answers, dimensions, updated_at
      FROM compatibility_profiles
      WHERE user_id = $1
    `, [userId]);

    const profile = result.rows[0] || {
      answers: {},
      dimensions: {},
      updated_at: null,
    };

    return fastify.sendSuccess(reply, profile);
  });

  // POST /compatibility/answers — Save or update questionnaire answers
  fastify.post('/answers', {
    onRequest: [fastify.authenticate],
    schema: {
      body: {
        type: 'object',
        required: ['answers'],
        properties: {
          answers: {
            type: 'object',
            properties: {
              communication: { type: 'object' },
              relationship_intentions: { type: 'object' },
              core_values: { type: 'array', items: { type: 'string' } },
              lifestyle: { type: 'object' },
              emotional_readiness: { type: 'object' },
              conflict_resolution: { type: 'object' },
              shared_interests: { type: 'array', items: { type: 'string' } },
            },
          },
        },
      },
    },
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { answers } = req.body;

    const dimensionsSummary = {
      communication_ready: !!answers.communication,
      intentions_ready: !!answers.relationship_intentions,
      values_ready: Array.isArray(answers.core_values) && answers.core_values.length > 0,
      lifestyle_ready: !!answers.lifestyle,
      readiness_ready: !!answers.emotional_readiness,
      conflict_ready: !!answers.conflict_resolution,
      interests_ready: Array.isArray(answers.shared_interests) && answers.shared_interests.length > 0,
    };

    await fastify.db.query(`
      INSERT INTO compatibility_profiles (user_id, answers, dimensions, updated_at)
      VALUES ($1, $2, $3, NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        answers = EXCLUDED.answers,
        dimensions = EXCLUDED.dimensions,
        updated_at = NOW()
    `, [userId, JSON.stringify(answers), JSON.stringify(dimensionsSummary)]);

    return fastify.sendSuccess(reply, {
      saved: true,
      dimensions_ready: dimensionsSummary,
      updated_at: new Date().toISOString(),
    });
  });

  // GET /compatibility/compare/:targetUserId — Calculate insights between user and candidate
  fastify.get('/compare/:targetUserId', {
    onRequest: [fastify.authenticate],
  }, async (req, reply) => {
    const userId = req.user.uid;
    const { targetUserId } = req.params;

    if (userId === targetUserId) {
      return fastify.sendError(reply, 'Cannot compare compatibility with yourself', 400);
    }

    // Check block list
    const blockCheck = await fastify.db.query(`
      SELECT 1 FROM blocks 
      WHERE (blocker_id = $1 AND blocked_id = $2) OR (blocker_id = $2 AND blocked_id = $1)
    `, [userId, targetUserId]);

    if (blockCheck.rows.length > 0) {
      return fastify.sendError(reply, 'Profile is not available for comparison', 403);
    }

    // Fetch both users' compatibility profiles
    const profilesResult = await fastify.db.query(`
      SELECT user_id, answers
      FROM compatibility_profiles
      WHERE user_id = $1 OR user_id = $2
    `, [userId, targetUserId]);

    const myProfile = profilesResult.rows.find(r => r.user_id === userId);
    const theirProfile = profilesResult.rows.find(r => r.user_id === targetUserId);

    const myAnswers = myProfile?.answers || {};
    const theirAnswers = theirProfile?.answers || {};

    const calculation = calculateDimensionAlignment(myAnswers, theirAnswers);

    return fastify.sendSuccess(reply, {
      target_user_id: targetUserId,
      ...calculation,
    });
  });
};
