salty.activemq:
  force-delay-state: False
  root-volume-tags:
    owner: paulbruno
    purpose: salt dev root vol tag testing
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
