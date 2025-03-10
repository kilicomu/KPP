.. _input-for-kpp:

#############
Input for KPP
#############

KPP basically handles two types of files: **Kinetic description files** and
**auxiliary files**.  Kinetic description files are in KPP syntax and
described in the following sections.  Auxiliary files are described in
the section entitled :ref:`auxiliary-files-and-the-substitution-preprocessor`.

KPP kinetic description files specify the chemical equations, the
initial values of each of the species involved, the integration
parameters, and many other options. The KPP preprocessor parses the
kinetic description files and generates several output files. Files
that are written in KPP syntax have one of the suffixes :file:`.kpp`,
:file:`.spc`, :file:`.eqn`, or :file:`def`. An exception is the file
:file:`atoms`, which has no suffix.

The following general rules define the structure of a kinetic
description file:

-  A KPP program is composed of :ref:`kpp-sections`,
   :ref:`kpp-commands`, and :ref:`inlined-code`. Their syntax is
   presented in :ref:`bnf-description`.

-  Comments are either enclosed between the curly braces :code:`{` and
   :code:`}`, or written in a line starting with two slashes :code:`//`.

-  Any name given by the user to denote an atom or a species is
   restricted to be less than 32 character in length and can only
   contain letters, numbers, or the underscore character. The first
   character cannot be a number. All names are case insensitive.

The kinetic description files contain a detailed specification of the
chemical model, information about the integration method and the desired
type of results. KPP accepts only one of these files as input, but using
the :ref:`include-cmd` command, code from separate files can be
combined. The include files can be nested up to 10 levels. KPP will
parse these files as if they were a single big file. By carefully
splitting the chemical description, KPP can be configured for a broad
range of users. In this way the users can have direct access to that
part of the model that they are interested in, and all the other
details can be hidden inside several include files. Often, a file with
atom definitions is included first, then species definitions, and
finally the equations of the chemical mechanism.

.. _kpp-sections:

============
KPP sections
============

A :literal:`#` sign at the beginning of a line followed by a section
name starts a new KPP section. Then a list of items separated by
semicolons follows. A section ends when another KPP section or command
occurs, i.e. when another :literal:`#` sign occurs at the beginning of
a line. The syntax of an item definition is different for each
particular section.

.. _atoms:

#ATOMS
------

The atoms that will be further used to specify the components of a
species must be declared in an :command:`#ATOMS` section, e.g.:

.. code-block:: console

   #ATOMS N; O; Na; Br;

Usually, the names of the atoms are the ones specified in the periodic
table of elements. For this table there is a predefined file containing
all definitions that can be used by the command:

.. code-block:: console

   #INCLUDE atoms.kpp

This should be the first line in a KPP input file, because it allows to
use any atom in the periodic table of elements throughout the kinetic
description file.

.. _check:

#CHECK
------

KPP is able to do a mass balance checking for all equations. Some
chemical equations are not balanced for all atoms, and this might still
be correct from a chemical point of view. To accommodate for this, KPP
can perform mass balance checking only for the list of atoms specified
in the :command:`#CHECK` section, e.g.:

.. code-block:: console

   #CHECK N; C; O;

The balance checking for all atoms can be enabled by using the
:command:`#CHECKALL` command. Without :command:`#CHECK` or
:command:`#CHECKALL`, no checking is performed. The :literal:`IGNORE`
atom can also be used to control mass balance checking.

.. _defvar-and-deffix:

#DEFVAR and #DEFFIX
-------------------

There are two ways to declare new species together with their atom
composition: :command:`#DEFVAR` and :command:`#DEFFIX`. These sections
define all the species that will be used in the chemical
mechanism. Species can be variable or fixed. The type is implicitly
specified by defining the species in the appropriate sections. A
species can be considered fixed if its concentration does not vary too
much. The variable species are medium or short lived species and their
concentrations vary in time. This division of species into different
categories is helpful for integrators that benefit from treating them
differently.

For each species the user has to declare the atom composition. This
information is used for mass balance checking. If the species is a
lumped species without an exact composition, it can be ignored. To do
this one can declare the predefined atom :command:`IGNORE` as being
part of the species composition. Examples for these sections are:

.. code-block:: console

   #DEFVAR
     NO2 = N + 2O;
     CH3OOH = C + 4H + 2O;
     HSO4m = IGNORE;
     RCHO = IGNORE;
   #DEFFIX
     CO2 = C + 2O;

.. _equations:

#EQUATIONS
----------

The chemical mechanism is specified in the :command:`#EQUATIONS`
section. Each equation is written in the natural way in which a
chemist would write it, e.g.:

.. code-block:: console

   #EQUATIONS
     NO2 + hv = NO + O : 0.533*SUN;
     OH + NO2 = HNO3 : k_3rd(temp,
       cair,2.E-30,3.,2.5E-11,0.,0.6);

Only the names of already defined species can be used. The rate
coefficient has to be placed at the end of each equation, separated by a
colon. The rate coefficient does not necessarily need to be a numerical
value. Instead, it can be a valid expression in the
`target language <language-cmd_>`_. If there are several
:command:`#EQUATIONS` sections in the input, their contents will be
concatenated.

A minus sign in an equation shows that a species is consumed in a
reaction but it does not affect the reaction rate. For example, the
oxidation of methane can be written as:

.. code-block:: console

   CH4 + OH = CH3OO + H2O - O2 : k_CH4_OH;

However, it should be noted that using negative products may lead to
numerical instabilities.

Often, the stoichiometric factors are integers. However, it is also
possible to have non-integer yields, which is very useful to
parameterize organic reactions that branch into several side reactions:

.. code-block:: console

   CH4 + O1D = .75 CH3O2 + .75 OH + .25 HCHO
               + 0.4 H + .05 H2 : k_CH4_O1D;

KPP provides two pre-defined dummy species: :literal:`hv` and
:literal:`PROD`. Using dummy species does not affect the numerics of
the integrators. It only serves to improve the readability of the
equations. For photolysis reactions, :literal:`hv` can be specified as
one of the reagents to indicate that light (:math:`h\nu`) is needed for this
reaction, e.g.:

.. code-block:: console

   NO2 + hv = NO + O : J_NO2;

When the products of a reaction are not known or not important, the
dummy species :literal:`PROD` should be used as a product. This is
necessary because the KPP syntax does not allow an empty list of
products. For example, the dry deposition of atmospheric ozone to the
surface can be written as:

.. code-block:: console

   O3 = PROD : v_d_O3;

The same equation must not occur twice in the :command:`#EQUATIONS`
section. For example, you may have both the gas-phase reaction of :literal:`N2O5` with
water in your mechanism and also the heterogeneous reaction on aerosols:

.. code-block:: console

   N2O5 + H2O = 2 HNO3 : k_gas;
   N2O5 + H2O = 2 HNO3 : k_aerosol;

These reactions must be merged by adding the rate coefficients:

.. code-block:: console

   N2O5 + H2O = 2 HNO3 : k_gas+k_aerosol;

.. _families:

#FAMILIES
---------

Chemical families (for diagnostic purposes) may be specified in the
:command:`#FAMILIES` section as shown below.  Family names beginning
with a :code:`P` denote production, and those beginning with an
:code:`L` denote loss.

.. code-block:: console

   #FAMILIES
     POx : O3 + NO2 + 2NO3 + HNO3 + ... etc. add more species as needed ...
     LOx : O3 + NO2 + 2NO3 + HNO3 + ... etc. add more species as needed ...
     PCO : CO;
     LCO : CO;
     PSO4 : SO4;
     LCH4 : CH4;
     PH2O2 : H2O2;

KPP will examine the chemical mechanism and create a dummy species for
each defined family.  Each dummy species will archive the production
and loss for the family.  For example, each molecule of CO that is
produced will be added to the :code:`PCO` dummy species.  Likewise,
each molecule of CO that is consumed will be added to the :code:`LCO`
dummy species. This will allow the :code:`PCO` and :code:`LCO` species
to be later archived for diagnostic purposes. Dummy species for chemical
families will not be included as active species in the mechanism.

.. _initvalues:

#INITVALUES
-----------

The initial concentration values for all species can be defined in the
:command:`#INITVALUES` section, e.g.:

.. code-block:: console

   #INITVALUES
     CFACTOR = 2.5E19;
     NO2 = 1.4E-9;
     CO2 = MyCO2Func();
     ALL_SPEC = 0.0;

If no value is specified for a particular species, the default value
zero is used. One can set the default values using the generic species
names: :code:`VAR_SPEC`, :code:`FIX_SPEC`, and :code:`ALL_SPEC`. In order
to use coherent units for concentration and rate coefficients, it is
sometimes necessary to multiply each value by a constant factor. This
factor can be set by using the generic name :code:`CFACTOR`. Each of
the initial values will be multiplied by this factor before being
used. If :code:`CFACTOR` is omitted, it defaults to one.

The information gathered in this section is used to generate the :code:`Initialize`
subroutine (cf  :ref:`Initialize`). In more complex 3D
models, the initial values are usually taken from some input files or
some global data structures. In this case, :command:`#INITVALUES` may
not be needed.

.. _lookat-and-monitor:

#LOOKAT and #MONITOR
--------------------

There are two sections in this category: :command:`#LOOKAT` and
:command:`#MONITOR`.

The section instructs the preprocessor what are the species for which
the evolution of the concentration, should be saved in a data file. By
default, if no :command:`#LOOKAT` section is present, all the species
are saved. If an atom is specified in the :command:`#LOOKAT` list then
the total mass of the particular atom is reported. This allows to
check how the mass of a specific atom was conserved by the integration
method. The :command:`#LOOKATALL` command can be used to specify all
the species. Output of :command:`#LOOKAT` can be directed to the file
:file:`ROOT.dat` using the utility subroutines described in the
section entitled :ref:`Util`.

The :command:`#MONITOR` section defines a different list of species
and atoms. This list is used by the driver to display the
concentration of the elements in the list during the integration. This
may give us a feedback of the evolution in time of the selected
species during the integration. The syntax is similar to the
:command:`#LOOKAT` section. With the driver :code:`general`,
output of :command:`#MONITOR` goes to the screen (STDOUT). The order
of the output is: first variable species, then fixed species, finally
atoms. It is not the order in the :command:`MONITOR` command.

Examples for these sections are:

.. code-block:: console

   #LOOKAT NO2; CO2; O3; N;
   #MONITOR O3; N;

.. _lump:

#LUMP
-----

To reduce the stiffness of some models, various lumping of species may
be defined in the :command:`#LUMP` section. In the example below,
species :code:`NO` and :code:`NO2` are summed and treated as a single
lumped variable, :code:`NO2`. Following integration, the individual
species concentrations are recomputed from the lumped variable.

.. code-block:: console

   #LUMP NO2 + NO : NO2

.. _setvar-and-setfix:

#SETVAR and #SETFIX
-------------------

The commands :command:`#SETVAR` and :command:`#SETFIX` change the type of an
already defined species. Then, depending on the integration method,
one may or may not use the initial classification, or can easily move
one species from one category to another. The use of the generic
species :code:`VAR_SPEC`, :code:`FIX_SPEC`, and :code:`ALL_SPEC` is
also allowed. Examples for these sections are:

.. code-block:: console

   #SETVAR ALL_SPEC;
   #SETFIX H2O; CO2;

.. _transport:

#TRANSPORT
----------

The :command:`#TRANSPORT` section is only used for transport chemistry
models. It specifies the list of species that needs to be included in
the transport model, e.g.:

.. code-block:: console

   #TRANSPORT NO2; CO2; O3; N;

One may use a more complex chemical model from which only a couple of
species are considered for the transport calculations. The
:command:`#TRANSPORTALL` command is also available as a shorthand for
specifying that all the species used in the chemical model have to be
included in the transport calculations.

.. _kpp-commands:

============
KPP commands
============

A command begins on a new line with a :code:`#` sign, followed by a
command name and one or more parameters.  Details about each command
are given in the following subsections.

.. _declare-cmd:

#DECLARE
--------

The :command:`#DECLARE` command determines how constants like
:code:`dp`, :code:`NSPEC`, :code:`NVAR`, :code:`NFIX`, and
:code:`NREACT` are inserted into the KPP-generated code.
:command:`#DECLARE SYMBOL` (the default) will declare array variables
using parameters from the :ref:`Parameters` file. :command:`#DECLARE VALUE`
will replace each parameter with its value.

For example, the global array variable :code:`C` is declared in the
:ref:`Global` file generated by KPP.  In the :command:`small_strato`
example (described in :ref:`running-kpp-with-an-example-mechanism`),
:code:`C` has dimension :code:`NSPEC=7`. Using  :command:`#DECLARE
SYMBOL` will generate the following code in :ref:`Global`:

.. code-block:: F90

   ! C - Concentration of all species
     REAL(kind=dp), TARGET :: C(NSPEC)
     !$OMP THREADPRIVATE( C )

Whereas :command:`#DECLARE VALUE` will generate this code instead:

.. code-block:: F90

   ! C - Concentration of all species
     REAL(kind=dp), TARGET :: C(7)
     !$OMP THREADPRIVATE( C )

We recommend using :command:`#DECLARE SYMBOL`, as most modern
compilers will automatically replace each parameter (e.g. :code:`NSPEC`)
with its value (e.g :code:`7`).  This prevents repeated lookups of
the parameter value, which leads to inefficient execution.  But if you are
using a very old compiler that is not as sophisticated,
:command:`#DECLARE VALUE` might result in better-optmized code.

.. _double-cmd:

#DOUBLE
-------

The :command:`#DOUBLE` command selects single or double precision
arithmetic. :command:`ON` (the default) means use double precision,
:command:`OFF` means use single precision (see the section entitled
:ref:`Precision`).

.. important::

   We recommend using double precision whenever possible.  Using
   single precision may lead to integration non-convergence errors
   caused by roundoff and/or underflow.

.. _driver-cmd:

#DRIVER
-------

The :command:`#DRIVER` command selects the driver, i.e., the file from
which the main function is to be taken. The parameter is a file name,
without suffix. The appropriate suffix (:code:`.f90`, :code:`.F90`,
:code:`.c`, or :code:`.m`) is automatically appended.

Normally, KPP tries to find the selected driver file in the directory
:file:`$KPP_HOME/drv/`. However, if the supplied file name contains a slash,
it is assumed to be absolute. To access a driver in the current
directory, the prefix :file:`./` can be used, e.g.:

.. code-block:: console

   #DRIVER ./mydriver

It is possible to choose the empty dummy driver :command:`none`, if the
user wants to include the KPP generated modules into a larger model
(e.g. a general circulation or a chemical transport model) instead of
creating a stand-alone version of the chemical integrator. The driver
:command:`none` is also selected when the :command:`#DRIVER` command
is missing. If the command occurs twice, the second replaces the first.

.. _dummyindex-cmd:

#DUMMYINDEX
-----------

It is possible to declare species in the :ref:`defvar-and-deffix`
sections that are not used in the :ref:`equations` section. If your
model needs to check at run-time if a certain species is included in
the current mechanism, you can set to :command:`#DUMMYINDEX ON`. Then,
KPP will set the indices to zero for all species that do not occur in
any reaction. With :command:`#DUMMYINDEX OFF` (the default), those are
undefined variables. For example, if you frequently switch between
mechanisms with and without sulfuric acid, you can use this code:

.. code-block:: F90

   IF (ind_H2SO4=0) THEN
     PRINT *, 'no H2SO4 in current mechanism'
   ELSE
     PRINT *, 'c(H2SO4) =', C(ind_H2SO4)
   ENDIF

.. _eqntags-cmd:

#EQNTAGS
--------

Each reaction in the :command:`#EQNTAGS` section may start with an
equation tag which is enclosed in angle brackets, e.g.:

.. code-block:: console

   <J1> NO2 + hv = NO + O : 0.533*SUN;

With :command:`#EQNTAGS` set to :command:`ON`, this equation tag can
be used to refer to a specific equation
(cf. :ref:`lookat-and-monitor`). The default for :command:`#EQNTAGS`
is :command:`OFF`.

.. _function-cmd:

#FUNCTION
---------

The :command:`#FUNCTION` command controls which functions are generated
to compute the production/destruction terms for variable
species. :command:`AGGREGATE` generates one function that computes the
normal derivatives. :command:`SPLIT` generates two functions
for the derivatives in production and destruction forms.

.. _hessian-cmd:

#HESSIAN
--------

The option :command:`ON` (the default) of the :command:`#HESSIAN` command
turns the Hessian generation on (see the section entitled
:ref:`Hessian`).  With :command:`OFF` it is switched off.

.. _include-cmd:

#INCLUDE
--------

The :command:`#INCLUDE` command instructs KPP to look for the file
specified as a parameter and parse the content of this file before
proceeding to the next line. This allows the atoms definition, the
species definition and even the equation definition to be shared
between several models. Moreover this allows for custom configuration
of KPP to accommodate various classes of users. Include files can be
either in one of the KPP directories or in the current directory.

.. _integrator-cmd:

#INTEGRATOR
-----------

The :command:`#INTEGRATOR` command selects the integrator definition
file. The parameter is the file name of an integrator, without
suffix. The effect of

.. code-block:: console

   #INTEGRATOR integrator-name

is similar to:

.. code-block:: console

   #INCLUDE $KPP_HOME/int/integrator-name.def

If the :command:`#INTEGRATOR` the command occurs twice, the second
replaces the first.

.. _intfile-cmd:

#INTFILE
--------

.. attention::

   :command:`#INTFILE` is used internally by KPP but should not be used
   by the KPP user. Using :ref:`integrator-cmd` alone suffices to
   specify an integrator.

The integrator definition file selects an integrator file with
:command:`#INTFILE` and also defines some suitable options for it. The
:command:`#INTFILE` command selects the file that contains the integrator
routine. This command allows the use of different integration
techniques on the same model. The parameter of the
command is a file name, without suffix. The appropriate suffix
(:code:`.f90`, :code:`.F90`, :code:`.c`, or :code:`.m` is appended and
the result selects the file from which the integrator
is taken. This file will be copied into the code file in the appropriate
place. All integrators have to conform to the same specific calling
sequence. Normally, KPP tries to find the selected integrator file in
the directory :file:`$KPP_HOME/int/`. However, if the supplied file name
contains a slash, it is assumed to be absolute. To access an integrator
in the current directory, the prefix :file:`./` can be used, e.g.:

.. code-block:: console

   #INTEGRATOR ./mydeffile
   #INTFILE ./myintegrator

.. _jacobian-cmd:

#JACOBIAN
---------

The :command:`#JACOBIAN` command controls which functions are generated
to compute the Jacobian. The option :command:`OFF` inhibits the
generation of the Jacobian routine. The option :command:`FULL` generates
the Jacobian as a square :code:`NVAR x NVAR` matrix. It should be used
if the integrator needs the whole Jacobians. The options
:command:`SPARSE_ROW` and :command:`SPARSE_LU_ROW` (the default) both
generate the Jacobian in sparse (compressed on rows) format. They should
be used if the integrator needs the whole Jacobian, but in a sparse
form. The format used is compressed on rows. With
:command:`SPARSE_LU_ROW`, KPP extends the number of nonzeros to account
for the fill-in due to the LU decomposition.

.. _language-cmd:

#LANGUAGE
---------

The :command:`#LANGUAGE` command selects the target language in which the
code file is to be generated. Available options are :command:`Fortran90`,
:command:`C`, or :command:`matlab`.

.. tip::

   You can select the suffix (:code:`.F90` or :code:`.f90`) to use for
   Fortran90 source code generated by KPP (cf. :ref:`uppercasef90-cmd`).

.. _mex-cmd:

#MEX
----

:program:`Mex` is a Matlab extension that allows
to call functions written in Fortran and C directly from within the
Matlab environment. KPP generates the mex interface routines for the
ODE function, Jacobian, and Hessian, for the target languages C,
Fortran77, and Fortran90. The default is :command:`#MEX ON`. With
:command:`#MEX OFF`, no Mex files are generated.

.. _inversion-cmd:

#MINVERSION
-----------

You may restrict a chemical mechanism to use a given version of KPP or
later. To do this, add

.. code-block:: console

   #MINVERSION X.Y.Z

to the definition file.

The version number (:code:`X.Y.Z`) adheres to the Semantic
Versioning style (https://semver.org), where :code:`X` is the major
version number, :code:`Y` is the minor version number, and :code:`Z` is the
bugfix (aka “patch”) version number.

For example, if :command:`#MINVERSION 2.4.0` is specified, then KPP will
quit with an error message unless you are using KPP 2.4.0 or later.

.. _model-cmd:

#MODEL
------

The chemical model contains the description of the atoms, species, and
chemical equations. It also contains default initial values for the
species and default options including the best integrator for the model.
In the simplest case, the main kinetic description file, i.e. the one
passed as parameter to KPP, can contain just a single line selecting the
model. KPP tries to find a file with the name of the model and the
suffix :file:`.def` in the :file:`$KPP_HOME/models` subdirectory. This
file is then parsed. The content of the model definition file is
written in the KPP language. The model definition file points to a
species file and an equation file. The species file includes further
the atom definition file. All default values regarding the model are
automatically selected. For convenience, the best integrator and
driver for the given model are also automatically selected.

The :command:`#MODEL` command is optional, and intended for using a
predefined model. Users who supply their own reaction mechanism do not
need it.

.. _reorder-cmd:

#REORDER
--------

Reordering of the species is performed in order to minimize the fill-in
during the LU factorization, and therefore preserve the sparsity
structure and increase efficiency. The reordering is done using a
diagonal markowitz algorithm. The details are explained in
:cite:`1996:Sandu_et_al`. The default is :command:`ON`.
:command:`OFF` means that KPP does not reorder the species. The order
of the variables is the order in which the species are
declared in the :command:`#DEFVAR` section.

.. _stochastic-cmd:

#STOCHASTIC
-----------

The option :command:`ON` of the :command:`#STOCHASTIC` command turns
on the generation of code for stochastic kinetic simulations (see the
section entitled :ref:`Stochastic`.  The default option is :command:`OFF`.

.. _stoicmat-cmd:

#STOICMAT
---------

Unless the :command:`#STOICMAT` command is set to :command:`OFF`, KPP
generates code for the stoichiometric matrix, the vector of reactant
products in each reaction, and the partial derivative of the time
derivative function with respect to rate coefficients
(cf. :ref:`Stoichiom-and-StoichiomSP`).

.. _checkall-lookatall-transportall-cmd:

#CHECKALL, #LOOKATALL, #TRANSPORTALL
------------------------------------

KPP defines a couple of shorthand commands. The commands that fall into
this category are :command:`#CHECKALL`, :command:`#LOOKATALL`, and
:command:`#TRANSPORTALL`. All of them have been described in the
previous sections.

.. _uppercasef90-cmd:

#UPPERCASEF90
-------------

If you have selected :command:`#LANGUAGE Fortran90` option, KPP will
generate source code ending in :code:`.f90` by default. Setting
:command:`#UPPERCASEF90 ON` will tell KPP to generate Fortran90 code
ending in :code:`.F90` instead.

.. _inlined-code:

============
Inlined Code
============

In order to offer maximum flexibility, KPP allows the user to include
pieces of code in the kinetic description file. Inlined code begins on a
new line with :command:`#INLINE` and the *inline_type*. Next, one or
more lines of code follow, written in the target language (Fortran90,
C, or Matlab) as specified by the *inline_type*. The inlined code ends
with :command:`#ENDINLINE`. The code is inserted into the KPP output
at a position which is also determined by *inline_type* as explained
in :ref:`table-inl-type`. If two inline commands with the same inline
type are declared, then the contents of the second is appended to the
first one.

.. _list-of-inlined-types:

List of inlined types
---------------------

In this manual, we show the inline types for Fortran90. The inline
types for the other languages are produced by replacing :code:`F90`
by :code:`C`, or :code:`matlab`, respectively, as shown in
:ref:`table-inl-type`:

.. _table-inl-type:

.. table:: Table 1: KPP inlined types
   :align: center

   +-----------------+-------------------+---------------------+---------------------+
   | Inline_type     | File              | Placement           | Usage               |
   +=================+===================+=====================+=====================+
   | **F90_DATA**    | :ref:`Monitor`    | specification       | (obsolete)          |
   |                 |                   | section             |                     |
   +-----------------+-------------------+---------------------+---------------------+
   | **F90_GLOBAL**  | :ref:`Global`     | specification       | global variables    |
   |                 |                   | section             |                     |
   +-----------------+-------------------+---------------------+---------------------+
   | **F90_INIT**    | :ref:`Initialize` | subroutine          | integration         |
   |                 |                   |                     | parameters          |
   +-----------------+-------------------+---------------------+---------------------+
   | **F90_RATES**   | :ref:`Rates`      | executable section  | rate law functions  |
   +-----------------+-------------------+---------------------+---------------------+
   | **F90_RCONST**  | :ref:`Rates`      | subroutine          | statements and      |
   |                 |                   |                     | definitions of rate |
   |                 |                   |                     | coefficients        |
   +-----------------+-------------------+---------------------+---------------------+
   | **F90_UTIL**    | :ref:`Util`       | executable section  | utility functions   |
   +-----------------+-------------------+---------------------+---------------------+

.. _f90-data:

F90_DATA
--------

This inline type was introduced in a previous version of KPP to
initialize variables. It is now obsolete but kept for compatibility. For
Fortran90, :command:`F90_GLOBAL` should be used instead.

.. _f90-global:

F90_GLOBAL
----------

This inline type can be used to declare global variables, e.g. for a
special rate coefficient:

.. code-block:: F90

   #INLINE F90_GLOBAL
     REAL(dp) :: k_DMS_OH
   #ENDINLINE

.. _inline-type-f90-init:

F90_INIT
--------

This inline type can be used to define initial values before the start of the
integartion, e.g.:

.. code-block:: F90

   #INLINE F90_INIT
     TSTART = (12.*3600.)
     TEND = TSTART + (3.*24.*3600.)
     DT = 0.25*3600.
     TEMP = 270.
   #ENDINLINE

.. _f90-rates:

F90_RATES
---------

This inline type can be used to add new subroutines to calculate rate
coefficients, e.g.:

.. code-block:: F90

   #INLINE F90_RATES
     REAL FUNCTION k_SIV_H2O2(k_298,tdep,cHp,temp)
       ! special rate function for S(IV) + H2O2
       REAL, INTENT(IN) :: k_298, tdep, cHp, temp
       k_SIV_H2O2 = k_298 &
         * EXP(tdep*(1./temp-3.3540E-3)) &
         * cHp / (cHp+0.1)
     END FUNCTION k_SIV_H2O2
   #ENDINLINE

.. _f90-rconst:

F90_RCONST
----------

This inline type can be used to define time-dependent values of rate
coefficients that were declared with :

.. code-block:: F90

   #INLINE F90_RCONST
     k_DMS_OH = 1.E-9*EXP(5820./temp)*C(ind_O2)/ &
       (1.E30+5.*EXP(6280./temp)*C(ind_O2))
   #ENDINLINE

.. _f90-util:

F90_UTIL
--------

This inline type can be used to define utility subroutines.

.. _auxiliary-files-and-the-substitution-preprocessor:

=================================================
Auxiliary files and the substitution preprocessor
=================================================

The `auxiliary files <auxiliary-files-for-fortran-90_>`_ are
templates for integrators, drivers, and utilities. They are inserted
into the KPP output after being run through the substitution
preprocessor. This preprocessor replaces `several placeholder symbols
<list-of-symbols-replaced_>`_ in the template files
with their particular values in the model at hand. Usually, only
:command:`KPP_ROOT` and :command:`KPP_REAL` are needed because the other
values can also be obtained via the variables listed in
:ref:`table-inl-type`.

:command:`KPP_REAL` is replaced by the appropriate single or double
precision declaration  type. Depending on the target language KPP will
select the correct declaration type. For example if one needs to
declare an array BIG of size 1000, a declaration like the following
must be used:

.. code-block:: F90

   KPP_REAL :: BIG(1000)

When used with the option :code:`DOUBLE on`, the above line will be
automatically translated into:

.. code-block:: F90

   REAL(kind=dp) :: BIG(1000)

and when used with the option :code:`DOUBLE off`, the same line will become:

.. code-block:: F90

   REAL(kind=sp) :: BIG(1000)

in the resulting Fortran90 output file.

:command:`KPP_ROOT` is replaced by the root file name of the main kinetic
description file.  In our example where we are processing
:file:`small_strato.kpp`, a line in an auxiliary Fortran90 file like

.. code-block:: F90

   USE KPP_ROOT_Monitor

will be translated into

.. code-block:: F90

   USE small_strato_Monitor

in the generated Fortran90 output file.

.. _auxiliary-files-for-fortran-90:

List of auxiliary files for Fortran90
--------------------------------------

KPP inline codes or other instructions contained in the following
files, as shown in :ref:`table-aux-files`.

.. _table-aux-files:

.. table:: Table 2: Auxiliary files for Fortran90
   :align: center

   +-----------------------------+--------------------------------------------+
   | File                        | Contents                                   |
   +=============================+============================================+
   | ``dFun_dRcoeff.f90``        | Derivatives with respect to reaction       |
   |                             | rates.                                     |
   +-----------------------------+--------------------------------------------+
   | ``dJac_dRcoeff.f90``        | Derivatives with respect to reaction       |
   |                             | rates.                                     |
   +-----------------------------+--------------------------------------------+
   | ``Makefile_f90`` and        | Makefiles to build Fortran-90 code.        |
   | ``Makefile_upper_F90``      |                                            |
   +-----------------------------+--------------------------------------------+
   | ``Mex_Fun.f90``             | Mex files.                                 |
   +-----------------------------+--------------------------------------------+
   | ``Mex_Jac_SP.f90``          | Mex files.                                 |
   +-----------------------------+--------------------------------------------+
   | ``Mex_Hessian.f90``         | Mex files.                                 |
   +-----------------------------+--------------------------------------------+
   | ``sutil.f90``               | Sparse utility functions.                  |
   +-----------------------------+--------------------------------------------+
   | ``tag2num.f90``             | Function related to equation tags.         |
   +-----------------------------+--------------------------------------------+
   | ``UpdateSun.f90``           | Function related to solar zenith angle.    |
   +-----------------------------+--------------------------------------------+
   | ``UserRateLaws.f90``        | User-defined rate-law functions.           |
   +-----------------------------+--------------------------------------------+
   | ``util.f90``                | Input/output utilities.                    |
   +-----------------------------+--------------------------------------------+

.. _list-of-symbols-replaced:

List of symbols replaced by the substitution preprocessor
----------------------------------------------------------

The following symbols in KPP-generated source code will be replaced
with corresponding values, as highlighted in :ref:`table-sym-repl`.

.. _table-sym-repl:

.. table:: Table 3: Symbols and their replacements
   :align: center

   +--------------------+-------------------------------+---------------------+
   | Symbol             | Replacement                   | Example             |
   +====================+===============================+=====================+
   | **KPP_ROOT**       | The ``ROOT`` name             |  ``small_strato``   |
   +--------------------+-------------------------------+---------------------+
   | **KPP_REAL**       | The real data type            | ``REAL(kind=dp)``   |
   +--------------------+-------------------------------+---------------------+
   | **KPP_NSPEC**      | Number of species             | 7                   |
   +--------------------+-------------------------------+---------------------+
   | **KPP_NVAR**       | Number of variable species    | 5                   |
   +--------------------+-------------------------------+---------------------+
   | **KPP_NFIX**       | Number of fixed species       | 2                   |
   +--------------------+-------------------------------+---------------------+
   | **KPP_NREACT**     | Number of chemical            | 10                  |
   |                    | reactions                     |                     |
   +--------------------+-------------------------------+---------------------+
   | **KPP_NONZERO**    | Number of Jacobian nonzero    | 18                  |
   |                    | elements                      |                     |
   +--------------------+-------------------------------+---------------------+
   | **KPP_LU_NONZERO** | Number of Jacobian nonzero    | 19                  |
   |                    | elements, with LU fill-in     |                     |
   +--------------------+-------------------------------+---------------------+
   | **KPP_LU_NHESS**   | Number of Hessian nonzero     | 10                  |
   |                    | elements                      |                     |
   +--------------------+-------------------------------+---------------------+
