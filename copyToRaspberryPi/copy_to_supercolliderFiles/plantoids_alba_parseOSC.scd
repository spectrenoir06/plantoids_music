// Parse OSC and send msg values to worker functions
// Allows to decouple the OSC message parsing and the composition


// this maps analog index to worker functions

~ldr_max = 1024;
~sonar_max = 500;
~temperature_max = 50;
~humidity_max = 10;

~p1_analogSensorsMaxCount = 20;
~p2_analogSensorsMaxCount = 20;
~p3_analogSensorsMaxCount = 20;

~analogSensorsPrev = Array.newClear(3);
~analogSensorsPrev[0] = Array.fill(~p1_analogSensorsMaxCount, 0);
~analogSensorsPrev[1] = Array.fill(~p2_analogSensorsMaxCount, 0);
~analogSensorsPrev[2] = Array.fill(~p3_analogSensorsMaxCount, 0);

// at night, LDRs trigger onsets when value goes OVER threshold,
// during day, it's the opposite.

~isNightMode = false;


/*
Returns a state index based on previous and current values of light sensors:
isNoteOn: 2
isNoteOff: -1
isOn: 1
isOff: 0
*/
~lightOnset = { |plantIndex=0, sensorIndex=0, newValue=0, thresh=0.5|
	var prevVal, isNoteOn, isNoteOff, isOn, isOff, returnState;

	prevVal = ~analogSensorsPrev[plantIndex][sensorIndex];
	if (~isNightMode, {newValue = 1-newValue; prevVal = 1-prevVal;});

	isNoteOn = (prevVal <= thresh) && (newValue >= thresh);
	isNoteOff = (prevVal >= thresh) && (newValue <= thresh);
	isOn = (prevVal >= thresh) && (newValue >= thresh);
	isOff = (prevVal < thresh) && (newValue < thresh);

	if (isNoteOn,  {returnState=2});
	if (isNoteOff,  {returnState=1});
	if (isOn,  {returnState=1});
	if (isOff,  {returnState=0});
	returnState;
};

// ------------------------------------------  Plant 1
OSCdef(\p1_parseAnalogSensors).free;
OSCdef(\p1_parseAnalogSensors, {
	| msg, time, addr, port |

	var val, index, mapped, lightOnsetState;
	index = msg[1]; // numbered from 1 in OSC...
	val = msg[2] / ~ldr_max;

	lightOnsetState =~lightOnset.value(plantIndex:1, sensorIndex:index, newValue:val);

	switch(index,
		1, ~p1_flower_ambientLight.value(0, val),
		2, ~p1_flower_flexQuake.value(0, val),
		3, ~p1_flower_flexWind.value(0, val),
		4, ~p1_leaves_light.value(0, val, lightOnsetState),
		5, ~p1_leaves_light.value(1, val, lightOnsetState)
	);
	if(
		( index > 5 ),
		{~p1_stem_light.value( (index-6),  val, lightOnsetState)},
		{}
	);

	~analogSensorsPrev[0][index] = val;

}, '/plantoid/1/1/analog', n);

OSCdef(\p1_parseSonars).free;
OSCdef(\p1_parseSonars, {
	| msg, time, addr, port |
	var val, index, mapped;
	index = msg[1]; // numbered from 1 in OSC...
	val = msg[2] / ~sonar_max;
	~p1_stem_sonar.value(index-1, val);
}, '/plantoid/1/1/sonar', n);

OSCdef(\p1_parseTemperature).free;
OSCdef(\p1_parseTemperature, {
	| msg, time, addr, port |
	var val;
	val = msg[1] / ~temperature_max;
	~p1_flower_temperature.value(0, val);
}, '/plantoid/1/1/temp', n);

OSCdef(\p1_parseHumidity).free;
OSCdef(\p1_parseHumidity, {
	| msg, time, addr, port |
	var val;
	val = msg[1] / ~humidity_max;
	~p1_flower_humidity.value(0, val);
}, '/plantoid/1/1/hum', n);

// ------------------------------------------  Plant 2
OSCdef(\p2_parseAnalogSensors).free;
OSCdef(\p2_parseAnalogSensors, {
	| msg, time, addr, port |

	var val, index, mapped, lightOnsetState;
	index = msg[1]; // numbered from 1 in OSC...
	val = msg[2] / ~ldr_max;

	lightOnsetState =~lightOnset.value(plantIndex:1, sensorIndex:index, newValue:val);

	switch(index,
		1, ~p2_flower_flexQuake.value(0, val),
		2, ~p2_leaves_light.value(0, val, lightOnsetState);,
		3, ~p2_leaves_light.value(1, val, lightOnsetState)
	);
	if(
		( index > 3 ),
		{~p2_stem_light.value( (index-4),  val, lightOnsetState)},
		{}
	);

	~analogSensorsPrev[1][index] = val;

}, '/plantoid/2/1/analog', n);

OSCdef(\p2_parseSonars).free;
OSCdef(\p2_parseSonars, {
	| msg, time, addr, port |
	var val, index, mapped;
	index = msg[1]; // numbered from 1 in OSC...
	val = msg[2] / ~sonar_max;
	~p2_stem_sonar.value(index-1, val);
}, '/plantoid/2/1/sonar', n);


// ------------------------------------------  Plant 3
OSCdef(\p3_parseAnalogSensors).free;
OSCdef(\p3_parseAnalogSensors, {
	| msg, time, addr, port |

	var val, index, mapped, lightOnsetState;
	index = msg[1]; // numbered from 1 in OSC...
	val = msg[2] / ~ldr_max;

	lightOnsetState =~lightOnset.value(plantIndex:2, sensorIndex:index, newValue:val);

	switch(index,
		1, ~p3_flower_flexQuake.value(0, val),
		8, ~p3_leaves_light.value(0, val, lightOnsetState),
		9, ~p3_leaves_light.value(1, val, lightOnsetState)
	);
	if(
		( (index > 1)  && (index < 8) ),
		{~p3_flower_light.value( (index-2),  val, lightOnsetState)},
		{}
	);

	~analogSensorsPrev[2][index] = val;

}, '/plantoid/3/1/analog', n);

OSCdef(\p3_parseSonars).free;
OSCdef(\p3_parseSonars, {
	| msg, time, addr, port |
	var val, index, mapped;
	index = msg[1]; // numbered from 1 in OSC...
	val = msg[2] / ~sonar_max;
	~p3_stem_sonar.value(index-1, val);
}, '/plantoid/3/1/sonar', n);


