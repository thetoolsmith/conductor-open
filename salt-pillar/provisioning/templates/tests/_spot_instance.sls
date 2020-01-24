salty.activemq:
  force-delay-state: True
  spot_config:
    spot_price: 0.10
    tag:
      contact: paul bruno
      purpose: salt spot request tag testing
  root-volume-tags:
    owner: paulbruno
    purpose: salt dev spot instance testing
    Contact: paul bruno
    Team: salty 
  persist-volumes: False
  role: salty.activemq
  basename: mqXX.REGION.ENV
  nodes: 1
  size: t2.small
  tags:
    owner: paulbruno
    purpose: salt dev testing
    Contact: paul bruno
    Team: salty
