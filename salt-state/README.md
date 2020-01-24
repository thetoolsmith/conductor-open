# salt-state
# state tree

About new-instance.sls

This is a generic state used to apply to all new provisioned minions when using conductor salt runner.
This state will enumerate a pillar list value and check each minion it is applied to, and see if that minon has a role or roles
grain that maps to one of the states in the list from pillar. 

There are specific ways to enable this in pillar for a new role. See pillar model for details.
ref: https://github.com/orgX/salt-pillar/blob/test/config/common.sls#L22-L47

new-instance state can also now take in a nested dictionary of pillarkey value pairs to pass thru to the state/s is needs to apply to any given minon.
The purpose of this addition was to allow the new statepillars argument to conductor to be passed thru to the correct salt states even when using new-instance
as the default startup state with salt cloud conf files.

If this pillar parameter is not used when calling new-instance.sls, you must set the startup-override: [state1,state2] for the role in the 'provisioning' pillar template
if you need to pass dynamic pillar downstream to the role salt state.
I.E. pillar://provisioning/templates/your_roles_config

The pillar must be passed in using reserved id, 'state-pillars'
This is the only pillar parameter available to new-instance.sls. A real example is shown below. 

salt 'salty-activemq-01.us-east-1a.test.foobar.com' state.sls new-instance pillar='{"state-pillars": {"salty.activemq": {"version": "5.15.5"}}}'

The above salt command targets a minion and uses new-instance state to then apply the role specific salt states AND allows us to pass in dynamic pillar
(that the role state can optionally take) thru the new-instance generic startup state.
Note that the state-pillars is the dictionary key and it's value is a nested dictionary. 

So the 'pillar=' argument (this is the built-in salt option that is always available in any state call), is being set to a double nested python dictionary 3 deep.

the yaml representation would look like this...

pillar:                          <--- the built in salt option
  state-pillars:                 <--- our new pillar option for new-instance.sls state
    salty.activemq:              <--- the first (and only) key in the nested dictionary denotes the actual role state we need to pass dynamic pillar thru
      version: 5.15.5            <--- the only pillar key value pair we are passing into salty.activemq state

 
To provide a complex context. 
Suppose the salty.activemq salt state also applied the java salt state and we needed to dynamically change the java version when applying the role state.
Also suppose that the salty.activemq role state was not the only state that had to get applied to a minion for some reason (there's many ways to struture the role/state model). 

The command gets more complex with multiple dictionary values at each level, and would look like this


salt 'salty-activemq-01.us-east-1a.test.foobar.com' state.sls new-instance pillar='{"state-pillars": {"salty.activemq": {"version": "5.15.5", "java-version": "1.8.0_181"}, "salty.dummy": {"version": "2.2.2"}}}'

the yaml representation would look like this...

pillar:                          <--- the built in salt option
  state-pillars:                 <--- our new pillar option for new-instance.sls state
    salty.activemq:              <--- the first key in the nested dictionary denotes the actual role state we need to pass dynamic pillar thru
      version: 5.15.5            <--- one pillar key value pair dynamic pillar we are passing into salty.activemq state
      java-version: 1.8.0_181    <--- another pillar key value pair we are passing into salty.activemq state
    salty.dummy:                 <--- the second key in the nested dictionary denotes the actual role state we need to pass dynamic pillar thru
      version: 2.2.2             <--- the only key value pair dynamic pillar we are passing into salty.dummy state


