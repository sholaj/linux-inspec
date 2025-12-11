We are running InSpec controls that connect to Sybase via SSH on a jump server 
(jumpserver1). When executing the controls, InSpec fails with CS-LIBRARY and 
CT-LIBRARY errors indicating missing Sybase client libraries:

  common_cryptoutil_load(): Failed to load library '%1'
  ct_connect(): internal Client Library error

However, when we manually source the Sybase environment file:

  . /usr/local/sybase/SYBASE.sh

the same isql command works correctly.

Root cause appears to be that InSpec uses a non-interactive SSH session which does 
not load SYBASE.sh, leading to missing SYBASE, SYBASE_OCS, and LD_LIBRARY_PATH 
variables.

We need guidance on the recommended InSpec pattern for sourcing Sybase environment 
files before executing SQL commands through InSpec.