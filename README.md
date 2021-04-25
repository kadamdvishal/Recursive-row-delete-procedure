# Recursive-row-delete-procedure

It deletes all rows in the table specified that conform to the criteria selected, while also deleting any child/grandchild records and so on. This is designed to do the same sort of thing as Access's cascade delete function. 
It first reads the sysforeignkeys table to find any child tables, then deletes the soon-to-be orphan records from them using recursive calls to this procedure. 
Once all child records are gone, the rows are deleted from the selected table. It is designed at this time to be run at the command line. It could also be used in code, but the printed output will not be available.


