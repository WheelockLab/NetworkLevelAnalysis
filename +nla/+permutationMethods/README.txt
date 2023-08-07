README for adding new methods to this permutationMethods class

The goal of these objects is to implement a 'permute' method that takes an input struct and runs one random permutation on it.

WARNING WARNING WARNING
If any of the fields of input struct inherit from 'handle' (and are therefore pass by reference),
make sure that when permuting you make a deep copy of the struct before modifying, otherwise you will be altering
both the new permuted struct and the input struct!!!

FOR EXAMPLE
Imagine you are permuting a struct with data in a class ScanData that inherits from handle
and has a field called 'id' that is an array.
ie, origStruct.scanData is a class that inherits from handle, and origStruct.scanData.id is an array in that class.

If you do the following:

    newStruct = origStruct;
    newStruct.scanData.id = randperm(1:100);

that second line changes the id of scanData in both newStruct and origStruct, 
since they both have just a reference to the scanData obejct rather than a unique copy

SOLUTION
If you do want to permute data that is in a class that inherits from handle, 
you'll need to make a deep copy of it in the new permuted struct.
for example, if you made a 'copy' method for the ScanData object that made a new instance of the scanData class, you could do
        
    newStruct = origStruct;
    newStruct.scanData = newStruct.scanData.copy();
    newStruct.scanData.id = randperm(1:100);

and now that last line only alters the data in newStruct, and origStruct is left unmodified