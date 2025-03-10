.. _developer-info:

##############################
Information for KPP developers
##############################

This chapter is meant for KPP Developers. It describes the internal
architecture of the KPP preprocessor, the basic modules and their
functionalities, and the preprocessing analysis performed on the input
files. KPP can be very easily configured to suit a broad class of users.

.. _directory-structure:

=======================
KPP directory structure
=======================

The KPP distribution will unfold a directory :envvar:`$KPP_HOME` with the
following subdirectories:

.. option:: src/

   Contains the KPP source code files, as listed in :ref:`table-kpp-dirs`.

.. _table-kpp-dirs:

.. table:: Table 17. KPP source code files
   :align: center

   +-----------------------+-------------------------------------+
   | File                  | Description                         |
   +=======================+=======+=============================+
   | :file:`kpp.c`         | Main program                        |
   +-----------------------+-------------------------------------+
   | :file:`code.c`        | generic code generation functions   |
   +-----------------------+-------------------------------------+
   | :file:`code.h`        | Header file                         |
   +-----------------------+-------------------------------------+
   | :file:`code_c.c`      | Generation of C code                |
   +-----------------------+-------------------------------------+
   | :file:`code_f90.c`    | Generation of F90 code              |
   +-----------------------+-------------------------------------+
   | :file:`code_matlab.c` | Generation of Matlab code           |
   +-----------------------+-------------------------------------+
   | :file:`debug.c`       | Debugging output                    |
   +-----------------------+-------------------------------------+
   | :file:`gdata.h`       | Header file                         |
   +-----------------------+-------------------------------------+
   | :file:`gdef.h`        | Header file                         |
   +-----------------------+-------------------------------------+
   | :file:`gen.c`         | Generic code generation functions   |
   +-----------------------+-------------------------------------+
   | :file:`lex.yy.c`      | Flex/Bison generated file           |
   +-----------------------+-------------------------------------+
   | :file:`scan.h`        | Input for Flex and Bison            |
   +-----------------------+-------------------------------------+
   | :file:`scan.l`        | Input for Flex                      |
   +-----------------------+-------------------------------------+
   | :file:`scan.y`        | Input for Bison                     |
   +-----------------------+-------------------------------------+
   | :file:`scanner.c`     | Evaluate parsed input               |
   +-----------------------+-------------------------------------+
   | :file:`scanutil.c`    | Evaluate parsed input               |
   +-----------------------+-------------------------------------+
   | :file:`y.tab.c`       | Flex/Bison generated file           |
   +-----------------------+-------------------------------------+
   | :file:`y.tab.h`       | Flex/Bison generated header file    |
   +-----------------------+-------------------------------------+

.. option:: bin/

   Contains the KPP executable. The path to this directory
   needs to be added to the environment variable.

.. option:: util/

   Contains different function templates useful for the
   simulation. Each template file has a suffix that matches the
   appropriate target language (:code:`Fortran90`, :code:`C`, or
   :code:`Matlab`). KPP will run the template files through the
   substitution preprocessor (cf. :ref:`list-of-symbols-replaced`).
   The user can define their own auxiliary functions by inserting them
   into the files.

.. option:: models/

   Contains the description of the chemical models. Users
   can define their own models by placing the model description files in
   this directory. The KPP distribution contains several models from
   atmospheric chemistry which can be used as templates for model
   definitions.

.. option:: drv/

   Contains driver templates for chemical simulations. Each
   driver has a suffix that matches the appropriate target language
   (:code:`Fortran90`, :code:`C`, or :code:`Matlab`). KPP will run the
   appropriate driver through the substitution preprocessor
   (cf. :ref:`list-of-symbols-replaced`). The driver template provided
   with the distribution works with any example. Users can define here
   their own driver templates.

.. option:: int/

   Contains numerical time stepping (integrator) routines. The
   command “*integrator*” will force KPP to look into this directory for
   a definition file *integrator*. This file selects the numerical
   routine (with the command) and sets the function type, the Jacobian
   sparsity type, the target language, etc. Each integrator template is
   found in a file that ends with the appropriate suffix
   (:code:`.f90`, :code:`.F90`, :code:`c`, or :code:`matlab`).  The
   selected template is processed by the
   substitution preprocessor (cf. :ref:`list-of-symbols-replaced`).
   Users can define here their own numerical integration routines.

.. option:: examples/

   Contains several model description examples (:file:`.kpp` files)
   which can be used as templates for building simulations with KPP.

.. option:: site-lisp/

   Contains the file which provides a KPP mode for emacs with color
   highlighting.

.. option:: ci-tests

   Folders that define several continuous integraton test.  Each
   folder contains the following files (or symbolic links):

   For more information, please see :ref:`ci-tests`.

.. option:: .ci-pipelines/

   Hidden folder containing a YAML file with settings for automatically
   running the continuous integration tests on `Azure DevOps Pipelines
   <https://azure.microsoft.com/en-us/services/devops/pipelines/>`_

   Also contains bash scripts (ending in :file:`.sh`) for running the
   continuous integration tests either automatically in Azure Dev
   Pipelines, or manually from the command line.  For more
   information, please see :ref:`ci-tests`.

.. _kpp-env-vars:

=========================
KPP environment variables
=========================

In order for KPP to find its components, it has to know the path to the
location where the KPP distribution is installed. This is achieved by
requiring the :envvar:`$KPP_HOME` environment variable to be set to the path
where KPP is installed.

The :envvar:`PATH` variable should be updated to contain the
:file:`$KPP_HOME/bin` directory.

There are also several optional environment variable that control the places
where KPP looks for module files, integrators, and drivers.  All KPP
environment variables are summarized in the subsections below.

.. option:: KPP_HOME

   Required, stores the absolute path to the KPP distribution.

Default setting: none

.. option:: KPP_MODEL

   Optional, specifies additional places where KPP will look for model
   files before searching the default location.

   Default setting: :file:`$KPP_HOME/models`.

.. option:: KPP_INT

   Optional, specifies additional places where KPP will look for
   integrator files before searching the default.

   Default setting: :file:`$KPP_HOME/int`.

.. option:: KPP_DRV

   Optional specifies additional places where KPP will look for driver
   files before searching the default folder.

   Default setting: :file:`$KPP_HOME/drv`

.. _kpp-internal-modules:

====================
KPP internal modules
====================

.. _scanner-parser:

Scanner and parser
------------------

This module is responsible for reading the kinetic description files and
extracting the information necessary in the code generation phase. We
make use of the flex and bison generic tools in implementing our own
scanner and parser. Using these tools this module gathers information
from the input files and fills in the following data structures in
memory:

-  The atom list

-  The species list

-  The left hand side matrix of coefficients

-  The right hand side matrix of coefficients

-  The equation rates

-  The option list

Error checking is performed at each step in the scanner and the parser.
For each syntax error the exact line and input file, along with an
appropriate error message are produced. In most of the cases the exact
cause of the error can be identified, therefore the error messages are
very precise. Some other errors like mass balance, and equation
duplicates, are tested at the end of this phase.

.. _species-reordering:

Species reordering
------------------

When parsing the input files, the species list is updated as soon as a
new species is encountered in a chemical equation. Therefore the
ordering of the species is the order in which they appear in the
equation description section. This is not a useful order for subsequent
operations. The species have to be first sorted such that all variable
species and all fixed species are put together. Then if a sparsity
structure of the Jacobian is required, it might be better to reorder the
species in such a way that the factorization of the Jacobian will
preserve the sparsity. This reordering is done using a Markovitz type of
algorithm.

.. _expression-trees:

Expression trees computation
----------------------------

This is the core of the preprocessor. This module has to generate the
production/destruction functions the Jacobian and all the data structure
nedeed by these functions. This module has to build a language
independent structure of each function and statement in the target
source file. Instead of using an intermediate format for this as some
other compilers do, KPP generates the intermediate format for just one
statement at a time. The vast majority of the statements in the target
source file are assignments. The expression tree for each assignment is
incrementally build by scanning the coefficient matrices and the rate
constant vector. At the end these expression trees are simplified.
Similar approaches are applied to function declaration and prototypes,
data declaration and initialization.

.. _code-generation:

Code generation
---------------

There are basically two modules, each dealing with the syntax
particularities of the target language. For example, the C module
includes a function that generates a valid C assignment when given an
expression tree. Similarly there are functions for data declaration,
initializations, comments, function prototypes, etc. Each of these
functions produce the code into an output buffer. A language specific
routine reads from this buffer and splits the statements into lines to
improve readability of the generated code.

.. _adding-new-commands:

Adding new KPP commands
-----------------------

To add a new KPP command, the source code has to be edited at several
locations. A short summary is presented here, using the new command as
an example:

-  Add to several files in the directory:

.. code-block:: C

   void CmdNEWCMD( char *cmd );
   -  : ``{ "NEWCMD", PRM_STATE, NEWCMD },``

   -  : ``void CmdNEWCMD( char *cmd )``

   -  :

      -  ``%token NEWCMD``

      -  ``NEWCMD PARAMETER``

      -  ``{ CmdNEWCMD( $2 ); }``

-  Add a :ref:`ci-tests`:

   -  Create a new directory

   -  Add new :ref:`ci-tests` to the :file:`ci-tests` folder and
      update the scripts in :file:`.ci-pipelines` folder.

-  Other:

   -  Explain in user manual:

      -  Add to table

      -  Add a section

      -  Add to BNF description table

.. _ci-tests:

============================
Continuous integration tests
============================

In KPP 2.4.0 and later, we have added several continuous integration
(aka C-I) tests.  These are tests that compile the KPP source code into
an executable, build a sample chemistry mechanism, and run
a short "box model" simulation.  This helps to ensure that new
features and updates added to KPP will not break any existing
functionality.

The continuous integration tests will run automatically on `Azure
DevOps Pipelines
<https://azure.microsoft.com/en-us/services/devops/pipelines/>`_ each time a
commit is pushed to the `KPP Github repository
<https://github.com/KineticPreProcessor/KPP>`_.  You can also run the
integration tests locally on your own computer, as shown in the
following sections.

.. _list-of-ci-tests:

List of continuous integration tests
------------------------------------

:ref:`table-ci-tests` lists the C-I tests that are available in KPP
2.5.0.  All of the tests use the Fortran90 language.

.. _table-ci-tests:

.. table:: Table 18. Continuous integration tests
   :align: center

   +-----------------------+------------------------------------------------+
   | C-I test              | Description                                    |
   +=======================+================================================+
   | :file:`radau90`       | Uses the Runge-Kutta radau5 integrator         |
   |                       | with the SAPRC99 chemical mechanism.           |
   +-----------------------+------------------------------------------------+
   | :file:`rk`            | Uses the Runge-Kutta integrator                |
   |                       | with the small_strato chemical mechanism.      |
   +-----------------------+------------------------------------------------+
   | :file:`rktlm`         | Same as :file:`rk`, but uses the Runge-Kutta   |
   |                       | tangent-linear-model integrator.               |
   +-----------------------+------------------------------------------------+
   | :file:`ros`           | Uses the Rosenbrock integrator                 |
   |                       | with the small_strato chemical mechanism.      |
   +-----------------------+------------------------------------------------+
   | :file:`rosadj`        | Same as :file:`ros`, but uses the Rosenbrock   |
   |                       | adjoint integrator.                            |
   +-----------------------+------------------------------------------------+
   | :file:`rostlm`        | Same as :file:`ros`, but uses the Rosenbrock   |
   |                       | tangent linear method integrator.              |
   +-----------------------+------------------------------------------------+
   | :file:`rosenbrock90`  | Uses the Rosenbrock integrator with the        |
   |                       | SAPRC99 chemical mechanism.                    |
   +-----------------------+------------------------------------------------+
   | :file:`ros_minver`    | Same as :file:`rosenbrock90`, but tests the    |
   |                       | :command:`#MINVERSION` command. This test      |
   |                       | is successful if the bulding of the            |
   |                       | mechanism fails with a "KPP version too old"   |
   |                       | error.                                         |
   +-----------------------+------------------------------------------------+
   | :file:`ros_upcase`    | Same as :file:`rosenbrock90`, but tests if     |
   |                       | KPP can generate Fortran90 code with the       |
   |                       | :file:`.F90` suffix (i.e. with                 |
   |                       | :command:`#UPPERCASE ON`.                      |
   +-----------------------+------------------------------------------------+
   | :file:`saprc2006`     | Uses the Rosenbrock integrator with the        |
   |                       | SAPRCNOV chemical mechanism.                   |
   +-----------------------+------------------------------------------------+
   | :file:`sd`            | Uses the Runge-Kutta SDIRK integrator          |
   |                       | with the small_strato chemical mechanism.      |
   +-----------------------+------------------------------------------------+
   | :file:`sdadj`         | Same as :file:`sdadj`, but uses the            |
   |                       | Runge-Kutta SDIRK Adjoint integrator.          |
   +-----------------------+------------------------------------------------+
   | :file:`small_f90`     | Uses the LSODE integrator with the             |
   |                       | small_strato chemical mechanism.               |
   +-----------------------+------------------------------------------------+
   | :file:`small_strato`  | Uses the Rosenbrock integrator with the        |
   |                       | small_strato chemical mechanism.  This uses    |
   |                       | the same options as the example described in   |
   |                       | :ref:`running-kpp-with-an-example-mechanism`.  |
   +-----------------------+------------------------------------------------+

Each continuous integration test is contained in a subfolder of
:file:`$KPP_HOME/ci-tests` a KPP definition file (ending in
:file:`.kpp`) from :file:`$KPP_HOME/models/`.

.. _running-ci-tests-on-azure:

Running continuous integration tests on Azure DevOps Pipelines
--------------------------------------------------------------

The files that are needed to run the C-I tests are located in the
:file:`$KPP_HOME/.ci-pipelines` folder.  They are summarized in
:ref:`table-ci-pipelines`.

.. _table-ci-pipelines:

.. table:: Table 19. Files needed to execute C-I tests
   :align: center

   +-------------------------------------+------------------------------------+
   | File                                | Description                        |
   +=====================================+====================================+
   | :file:`Dockerfile`                  | Docker container with software     |
   |                                     | libraries for Azure DevOps         |
   |                                     | Pipelines                          |
   +-------------------------------------+------------------------------------+
   | :file:`build_testing.yml`           | Options for triggering C-I tests   |
   |                                     | on Azure DevOps Pipelines          |
   +-------------------------------------+------------------------------------+
   | :file:`ci-testing-script.sh`        | Driver script for running C-I      |
   |                                     | tests on Azure DevOps Pipelines    |
   +-------------------------------------+------------------------------------+
   | :file:`ci-manual-testing-script.sh` | Driver script for running C-I      |
   |                                     | tests on a local computer          |
   +-------------------------------------+------------------------------------+
   | :file:`ci-manual-cleanup-script.sh` | Script to remove files generated   |
   |                                     | when running C-I tests on a local  |
   |                                     | computer                           |
   +-------------------------------------+------------------------------------+

The :file:`Dockerfile` contains the software environment for `Azure
DevOps Pipelines
<https://azure.microsoft.com/en-us/services/devops/pipelines/>`_.  You
should not have to update this file.

File :file:`build_testing.yml` defines the runtime options for Azure
DevOps Pipelines.  The following settings determine which branches
will trigger C-I tests:

.. code-block:: yaml

   # Run a C-I test when a push to any branch is made.
   trigger:
     branches:
       include:
          - '*'
   pr:
     branches:
       include:
         - '*'

Currently this is set to trigger the C-I tests when a commit or pull
request is made to any branch of
`https://github.com/KineticPreProcessor/KPP
<https://github.com/KineticPreProcessor/KPP>`_.  This is the
recommended setting.  But you can restrict this so that only pushes or
pull requests to certain branches will trigger the C-I tests.

File :file:`ci-testing-script.sh` executes all of the C-I tests
whenever a push or a pull request is made to the selected branches
in the KPP Github repository.  If you add new C-I tests, be sure to
update the:code:`for` loop in this file.

.. _running-ci-tests-locally:

Running continuous integration tests locally
--------------------------------------------

To run the C-I tests on a local computer system, use these commands:

.. code-block:: console

   $ cd $KPP_HOME/.ci-pipelines
   ./ci-manual-testing-script.sh | tee ci-tests.log

This will run all of the C-I tests listed in :ref:`table-ci-tests` on
your own computer system and pipe the results to a log file.  This
will easily allow you to check if the results of the C-I tests are
identical to C-I tests that were run on a prior commit or pull
request.

To remove the files generated by the continuous integration tests, use
this command:

.. code-block :: console

   $ ./ci-manual-cleanup-script.sh

If you add new C-I tests, be sure to add the name of the new tests to
the :code:`for` loops in :file:`ci-manual-testing-script.sh` and
:file:`ci-manual-cleanup-script.sh`.
