# #################################################
# PILLAR TOP TO SUPPORT MULTIPLE SALT ENVIRONMENTS
#
# WE ONLY TARGET ONE ENVIRONMENT SINCE OUR PILLAR
# IS BRANCH PER SALT ENVIRONMENT
#
# NOTE: ALL PILLAR FILES THAT ARE DEFINED HERE WILL
# BE AVAIABLE IN THE RUNTIME PILLAR TREE.
# THIS MEANS THAT ALL THE ROLE ID'S DEFINED IN EACH
# PILLAR FILE MUST BE UNIQUE FOR THE ENVIRONMENT.
# THIS IS WHY NAMESPACING PILLAR FILES, STATE FILES
# AND ROLE ID'S IS VERY IMPORTANT. 
# #################################################

test:
  '*':
    - global
    - aws
    - config.common
    - config.salty
    - provisioning.templates.salty_roles
    - config.salty.systems
    - config.devops
    - provisioning.templates.devops_roles
    - config.devops.systems
  'product.group:salty':
    - match: grain
    - config.salty.test_group_pillar
  'G@product.group:salty and G@role:salty.dummy':
    - match: compound
    - config.salty.test_product_pillar
  'product.group:devops':
    - match: grain
    - config.devops
    - provisioning.templates.devops_roles
    - config.devops.systems
