Engine_32Harmony : CroneEngine {
	classvar root, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, polyphony;
	// audio buses
	var clock1Out, clock2Out, oscOutL, oscOutR, filterOut;
	// control buses
	var <>rate1In, <>rate2In, <>rootIn, <>range1In, <>range2In, <>attackIn, <>decayIn, <>lpfCutoffIn, <>hpfCutoffIn;
	var <>quantAmtIn, <>step0In, <>step1In, <>step2In, <>step3In, <>step4In, freqOutL, freqOutR;
	var freqMultIn;
	var createNodes, modGrp, audioGrp;
	var <clock1, <clock2, <leftSources, <rightSources, <filters, <saturation;
	var s, paramMap;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		s = context.server;

		// intervals
		root = 1;
		s1 = 2 ** (1/12);
		s2 = 2 ** (2/12);
		s3 = 2 ** (3/12);
		s4 = 2 ** (4/12);
		s5 = 2 ** (5/12);
		s6 = 2 ** (6/12);
		s7 = 2 ** (7/12);
		s8 = 2 ** (8/12);
		s9 = 2 ** (9/12);
		s10 = 2 ** (10/12);
		s11 = 2 ** (11/12);
		
		// remember to update the \clock SynthDef's hardcoded outbus param to match!
		polyphony = 16; // per output channel
		// remember to update the \clock SynthDef's hardcoded outbus param to match!
		
		// Audio Buses
		clock1Out = Array.fill(polyphony, {Bus.audio(s,1)});
		clock2Out = Array.fill(polyphony, {Bus.audio(s,1)});
		oscOutL = Bus.audio(s,1);
		oscOutR = Bus.audio(s,1);
		filterOut = Bus.audio(s,2);
		// Control Buses
		rate1In = Bus.control(s,1);
		rate2In = Bus.control(s,1);
		rootIn = Bus.control(s,1);
		range1In = Bus.control(s,1);
		range2In = Bus.control(s,1);
		attackIn = Bus.control(s,1);
		decayIn = Bus.control(s,1);
		lpfCutoffIn = Bus.control(s,1);
		hpfCutoffIn = Bus.control(s,1);
		quantAmtIn = Bus.control(s,1);
		step0In = Bus.control(s,1);
		step1In = Bus.control(s,1);
		step2In = Bus.control(s,1);
		step3In = Bus.control(s,1);
		step4In = Bus.control(s,1);
		freqOutL = Bus.control(s,1);
		freqOutR = Bus.control(s,1);
		freqMultIn = Bus.control(s,1);

		// norns control
		paramMap = IdentityDictionary[
			\rate1In -> (bus: rate1In),
			\rate2In -> (bus: rate2In),
			\rootIn -> (bus: rootIn),
			\range1In -> (bus: range1In),
			\range2In -> (bus: range2In),
			\attackIn -> (bus: attackIn),
			\decayIn -> (bus: decayIn),
			\lpfCutoffIn -> (bus: lpfCutoffIn),
			\hpfCutoffIn -> (bus: hpfCutoffIn),
			\quantAmtIn -> (bus: quantAmtIn),
			\step0In -> (bus: step0In),
			\step1In -> (bus: step1In),
			\step2In -> (bus: step2In),
			\step3In -> (bus: step3In),
			\step4In -> (bus: step4In),
			\freqOutL -> (bus: freqOutL),
			\freqOutR -> (bus: freqOutR),
			\freqMultIn -> (bus: freqMultIn)
		];

		// Initialize Buses
		rate1In.set(1);
		rate2In.set(1);
		range1In.set(4);
		range2In.set(4);
		rootIn.set(32.7);
		attackIn.set(0.01);
		decayIn.set(3.5);
		lpfCutoffIn.set(4000);
		hpfCutoffIn.set(20);
		quantAmtIn.set(50);
		step0In.set(root);
		step1In.set(s2);
		step2In.set(s4);
		step3In.set(s7);
		step4In.set(s9);
		freqOutL.set(0);
		freqOutR.set(0);
		freqMultIn.set(1);
		s.sync;

		// Create SynthDefs
    
    SynthDef(\clock, { |rate = 1, outBuses = #[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]|
    		var rand, index, sigs;
    
    		rand = Dust.ar(rate);
    		index = Stepper.ar(rand, 0, 0, polyphony-1, 1, 0);
    		sigs = Array.fill(polyphony, { |i|
    			((index-i).abs < 0.5 ) * rand;
    		});
    
    		polyphony.do { |i|
    			Out.ar(outBuses[i], sigs[i]);
    		};
    
    	}).add;

		SynthDef(\rando, {|outBus, rate, root, clockBus, quantAmt, rangeBus, freqBus|
			var freq, sig, pitches, timing, env, randOct, scale;
			var randClock = In.ar(clockBus);
			var attack = In.kr(attackIn, 1);
			var decay = In.kr(decayIn, 1);
			var range = In.kr(rangeBus, 1);
			var step0Quant = In.kr(step0In, 1);
			var step1Quant = In.kr(step1In, 1);
			var step2Quant = In.kr(step2In, 1);
			var step3Quant = In.kr(step3In, 1);
			var step4Quant = In.kr(step4In, 1);
			var step0 = SelectX.ar(quantAmt, [TRand.ar(1.0,2.0,randClock), K2A.ar(step0Quant)]);
			var step1 = SelectX.ar(quantAmt, [TRand.ar(1.0,2.0,randClock), K2A.ar(step1Quant)]);
			var step2 = SelectX.ar(quantAmt, [TRand.ar(1.0,2.0,randClock), K2A.ar(step2Quant)]);
			var step3 = SelectX.ar(quantAmt, [TRand.ar(1.0,2.0,randClock), K2A.ar(step3Quant)]);
			var step4 = SelectX.ar(quantAmt, [TRand.ar(1.0,2.0,randClock), K2A.ar(step4Quant)]);

			var freqMult = In.kr(freqMultIn, 1);
			randOct = TIRand.ar(1,range,randClock);
			scale = Drand([step0, step1, step2, step3, step4],inf);

			freq = Lag.kr(root,0.18) * freqMult;
			freq = freq * (Demand.ar(randClock, 0, scale) * (2 ** randOct));
			env = EnvGen.ar(envelope: Env.perc(attack, decay, 1), gate: randClock);
			sig = SinOsc.ar(freq);
			sig = sig * env * 0.04;
			Out.ar(outBus, sig);
			// freq tap for display
			Out.kr(freqBus, A2K.kr(freq));
		}).add;

		SynthDef(\filters, {|outBus, lpfCutoff, hpfCutoff|
			var sig;
			sig = [In.ar(oscOutL, 1), In.ar(oscOutR,1)];
			sig = HPF.ar(sig, hpfCutoff);
			sig = LPF.ar(sig, Lag.kr(lpfCutoff,0.18));
			Out.ar(outBus, sig);
		}).add;

		SynthDef(\saturation, {|inBus, outBus|
			var sig;
			sig = In.ar(filterOut, 2);
			sig = sig / 2;
			sig = (sig - DC.ar(0.6)).tanh + DC.ar(0.535);
			sig = sig * 2;
			Out.ar(outBus, sig);
		}).add;

		s.sync;
		// Create Groups
		modGrp = Group.head(s);
		s.sync;
		audioGrp = Group.tail(modGrp);
		s.sync;
		// Create Synths
		clock1 = Synth(\clock, [rate: rate1In.asMap, \outBuses: clock1Out.collect({|i| i.index})], 
			  modGrp);
		clock2 = Synth(\clock, [rate: rate2In.asMap, \outBuses: clock2Out.collect({|i| i.index})], 
			  modGrp);
		leftSources = Array.fill(polyphony, {|i|
			Synth(\rando, [outBus: oscOutL, rate: rate1In.asMap,
				root: rootIn.asMap, decay: decayIn.asMap, clockBus: clock1Out[i],
				quantAmt: quantAmtIn.asMap, rangeBus: range1In, freqBus: freqOutL], audioGrp);
		});
		rightSources = Array.fill(polyphony, {|i|
			Synth(\rando, [outBus:oscOutR, rate: rate2In.asMap,
				root: rootIn.asMap, decay: decayIn.asMap, clockBus: clock2Out[i],
				quantAmt: quantAmtIn.asMap, rangeBus: range2In, freqBus: freqOutR], audioGrp);
		});
		s.sync;
		filters = Synth.tail(audioGrp, \filters, [lpfCutoff: lpfCutoffIn.asMap, hpfCutoffIn.asMap, outBus: filterOut]);
		s.sync;
		saturation = Synth.tail(audioGrp, \saturation, [inBus: filterOut, outBus: 0]);
		// Create MIDI Handlers (todo...?)

		paramMap.keys.do { |name|
			this.addCommand(name, "f", { |msg|
				var param, value;
				param = paramMap[name];
				value = msg[1];

				if (param.notNil) {
					param[\bus].set(value);
				};
			});
		};
		
		}

	free {
		modGrp.free;
		audioGrp.free;
	}
}