USE [ProjectWorks]
GO
/****** Object:  StoredProcedure [dbo].[spADMINDeleteRows]    Script Date: 02/02/2021 23:43:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[spADMINDeleteRows]
/* Recursive row delete procedure. It deletes all rows in the table specified that conform to the criteria selected, while also deleting any child/grandchild records and so on. This is designed to do the same sort of thing as Access's cascade delete function. It first reads the sysforeignkeys table to find any child tables, then deletes the soon-to-be orphan records from them using recursive calls to this procedure. Once all child records are gone, the rows are deleted from the selected table. It is designed at this time to be run at the command line. It could also be used in code, but the printed output will not be available. */
(
	@cTableName varchar(255), /* name of the table where rows are to be deleted */
	@cCriteria nvarchar(max), /* criteria used to delete the rows required */
	@iRowsAffected int OUTPUT /* number of records affected by the delete */
)
As
set nocount on
declare @cTab varchar(255), /* name of the child table */ @cCol varchar(255), /* name of the linking field on the child table */
		@cRefTab varchar(255), /* name of the parent table */
		@cRefCol varchar(max), /* name of the linking field in the parent table */
		@cFKName varchar(max), /* name of the foreign key */
		@cSQL nvarchar(max), /* query string passed to the sp_ExecuteSQL procedure */
		@cChildCriteria nvarchar(max), /* criteria to be used to delete records from the child table */
		@iChildRows int /* number of rows deleted from the child table */
/* declare the cursor containing the foreign key constraint information */
DECLARE cFKey CURSOR LOCAL FOR SELECT SO1.name AS Tab, SC1.name AS Col, SO2.name AS RefTab, SC2.name AS RefCol, FO.name
AS FKName FROM dbo.sysforeignkeys FK
		INNER JOIN dbo.syscolumns SC1 ON FK.fkeyid = SC1.id AND FK.fkey = SC1.colid
		INNER JOIN dbo.syscolumns SC2 ON FK.rkeyid = SC2.id AND FK.rkey = SC2.colid
		INNER JOIN dbo.sysobjects SO1 ON FK.fkeyid = SO1.id
		INNER JOIN dbo.sysobjects SO2 ON FK.rkeyid = SO2.id
		INNER JOIN dbo.sysobjects FO ON FK.constid = FO.id
	WHERE SO2.Name = @cTableName OPEN cFKey FETCH NEXT FROM cFKey INTO @cTab, @cCol, @cRefTab, @cRefCol, @cFKName
		WHILE @@FETCH_STATUS = 0
BEGIN /* build the criteria to delete rows from the child table. As it uses the criteria passed to this procedure, it gets progressively larger with recursive calls */
	SET @cChildCriteria = @cCol + ' in (SELECT [' + @cRefCol + '] FROM [' + @cRefTab +'] WHERE ' + @cCriteria + ')'
	declare @cChildSelect nvarchar(max)
	declare @numRows int
	set @cChildSelect = 'select @numRows = count(*) from ' + @cTab + ' where ' + @cChildCriteria
	--print @cChildSelect
	EXEC sp_ExecuteSQL @cChildSelect,N'@numRows int OUTPUT', @numRows OUTPUT
	print @numRows
	if (@numRows > 0)
	begin
		print 'Traversing into from table ' + @cTab /* call this procedure to delete the child rows */
		EXEC spADMINDeleteRows @cTab, @cChildCriteria, @iChildRows OUTPUT
	end
		FETCH NEXT FROM cFKey INTO @cTab, @cCol, @cRefTab, @cRefCol, @cFKName
	END


	Close cFKey DeAllocate cFKey /* finally delete the rows from this table and display the rows affected */
	SET @cSQL = 'DELETE FROM [' + @cTableName + '] WHERE ' + @cCriteria print @cSQL
	EXEC sp_ExecuteSQL @cSQL print 'Deleted ' + CONVERT(varchar, @@ROWCOUNT) + ' records from table ' + @cTableName



/*
exec spADMINDeleteRows
'payroll_scale_master' ,
'payroll_scale_id in (select payroll_scale_id from payroll_scale_master)',
0
*/