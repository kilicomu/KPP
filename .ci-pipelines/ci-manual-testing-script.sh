#!/bin/sh

########################################################################
### CI tests for github.com/KineticPreProcessor/KPP                  ###
### NOTE: This script runs CI-tests manually (for testing/debugging) ###
########################################################################

# List of tests (add more as necessary; separate each with a space)
all_tests="radau90 rk rktlm ros rosadj rosenbrock90 rostlm saprc2006 sd sdadj small_f90 ros_upcase small_strato"

# Run each test
# Check status of each individual operation and exit if any do not complete
for this_test in $all_tests; do

    cd ../ci-tests/$this_test
    [ $? -ne 0 ] && exit 1

    echo ""
    echo ">>>>>>>> Generating $this_test mechanism with KPP <<<<<<<<"
    echo ""
    ../../bin/kpp $this_test.kpp
    [ $? -ne 0 ] && exit 1

    echo ""
    echo ">>>>>>>> Building the $this_test test executable <<<<<<<<<"
    echo ""
    make -j -f Makefile_$this_test COMPILER=GFORTRAN
    [ $? -ne 0 ] && exit 1

    echo ""
    echo ">>>>>>>> Running the $this_test test <<<<<<<<"
    echo ""
    ./$this_test.exe
    [ $? -ne 0 ] && exit 1

    echo ""
    echo ">>>>>>>> $this_test test was successful! <<<<<<<<"
    echo ""

    cd ..

done

# Run the ros_minver test, which tests if KPP will fail when the
# current version is older than the version specified #MINVERSION.
# NOTE: This test succeeds when KPP fails, so run it separately!
for this_test in "ros_minver"; do

    cd ../ci-tests/$this_test
    [ $? -ne 0 ] && exit 1

    echo ""
    echo ">>>>>>>> Generating $this_test mechanism with KPP <<<<<<<<"
    echo ""
    ../../bin/kpp $this_test.kpp
    [ $? -eq 0 ] && exit 1

    cd ..

done

# Return w/ success
echo ""
echo ">>>>>>>> All tests finished succesfully! <<<<<<<<"
echo ""
exit 0

