#!yaml|gpg

# #######################################################################################################
# THIS PILLAR HOLDS METADATA ABOUT EACH AWS REGION SUPPORTED FOR THE ENVIRONMENT
#
# ENVIRONMENTS CAN SPAN MULTIPLE REGIONS AND AZ'S	
# 
# saltmaster: can be a list or single string
#
# The management-vpc NEVER changes from environment to environment. the vpc: xxx changes as it represents
# the environment vpc.
# #########################################################################################################
ami-user-map:
  Amazon Linux: ec2-user
  RHEL: ec2-user
  CentOS: centos
  Ubuntu: ubuntu
  Debian: admin

us-east-1:
  management-vpc: vpc-xxxxxxxx
  vpc: vpc-xxxxxxxx
  ssh_username: ec2-user
  subnet:
    public:
      availability:
        zone_a: subnet-xxxxxxxx
    private:
      availability:
        zone_a: subnet-xxxxxxxx
  salt_master: 10.123.XX.XX
  security-group:
    management: sg-xxxxxxxx
    private: sg-xxxxxxxx
    public: sg-xxxxxxxx
  id: XXXXXXXXXXXXXXXXXXXXXXXXX
  key: |
    -----BEGIN PGP MESSAGE-----
    Version: GnuPG v2.0.22 (GNU/Linux)
    
    hIwDndYGtYR5UKMBA/9SPJ8+5WZHL0vQPd9U/+KjH/uIxfFr6je0FhsvPIw94Djo
    lo4Y3+knsmKcXGMgUm6f9hmgxnhN3hQ61yvCsObrZg4i1/avx2RfI0dDaid9i56m
    tFtU5FSD4Re36jDf7OZsd77gpYZLKSeBu+sIa0y/jtmlX425wxoaS3QvdTh/mdJj
    ASMB67L/YU9Ki2PhggCHO5W7QldWJj6O/ABTPSe1veZQ6bQRZ8LGFXgNthYQd41l
    llYjfkz2J3dwsWrxkYadxEArmUiZBf7L/o9fPp2VXEax6HVemQMgNA9u+mFCauRC
    Weku
    =REVC
    -----END PGP MESSAGE----- 

  private_key: /home/centos/.ssh/saltmaster_nonprod
  keyname: saltmaster_nonprod

