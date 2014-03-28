component {

	public function init(){
		return this;
	}

	public function setup(dataSource){
		variables.dataSource = arguments.dataSource;
	}

	public function dispense(componentName){
		try{
			var object = new "#componentName#"();
		}catch(any e){
			var object = new rb();		
		}		
		
		try{
			object.tableColumns = getColumns(componentName);
			object.primaryKey = getPrimaryKey(componentName);
		}catch(any e){
			object.tableColumns = ArrayNew(1);
			object.primaryKey = "";
		}

		object.ORMService = this;
		object.componentName = arguments.componentName;
		return object;
	}

	public function load(componentName,id){
		var primaryKey = getPrimaryKey(componentName);
		return this.find(arguments.componentName,"#primaryKey# = ? ",[id]);
	}

	public function find(componentName,where,values){
		var object = dispense(arguments.componentName);
		var records = whereQuery(componentName, where, values);
		if(records.recordcount > 0)
			return populateObject(object,records);
		else
			return false;
		return allObjects;
	}

	public function findAll(componentName,where,values){
		var records = whereQuery(componentName, where, values);
		var allObjects = arrayNew(1);
		for(var i = 1; i <= records.recordcount; i++){
			var object = dispense(arguments.componentName);
			object = populateObject(object, records, i);
			arrayAppend(allObjects,object);
		}
		return allObjects;	
	}

	public function store(object){
		var primaryKey = arguments.object.primaryKey;
		var primaryKeyValue = Evaluate("object.get#primaryKey#()");
		if(len(trim(primaryKey))){
			transaction{
				if(len(trim(primaryKeyValue))){
					return update(arguments.object);
				}else{
					return create(arguments.object);
				}
			}
		}else{
			return false;
		}
	}

	public void function storeAll(objects){
		transaction{
			for(var i = 1; i <= ArrayLen(objects); i ++){
				store(objects[i]);
			}
		}
	}

	public void function trash(object){
		var primaryKey = arguments.object.primaryKey;
		if(len(trim(primaryKey))){
			transaction{
				var primaryKeyValue = Evaluate("object.get#primaryKey#()");
				var queryService = new query();
				queryService.setDatasource(variables.dataSource); 
				queryService.setName(arguments.object.componentName);
				results = queryService.execute(sql="DELETE FROM #arguments.object.componentName# WHERE [#primaryKey#] = '#primaryKeyValue#'"); 
			}
		}
	}

	public function query(componentName, queryString){
		transaction{
			var results = queryThis(arguments.queryString);
			var records = results.getResult();
			var object = dispense(arguments.componentName);
			return populateObject(object, records);
		}
	}

	public function queryAll(componentName, queryString){
		transaction{
			var results = queryThis(queryString);
			var records = results.getResult();
			var allObjects = arrayNew(1);
			for(var i = 1; i <= records.recordcount; i++){
				var object = dispense(arguments.componentName);
				object = populateObject(object, records, i);
				arrayAppend(allObjects,object);
			}
			return allObjects;
		}
	}

	public function exportAll(objects){
		var exportArray = ArrayNew(1);
		for(var i = 1; i <= ArrayLen(objects); i ++){
			arrayAppend(exportArray,objects[i]._export());
		}
		return exportArray;
	}

	public function importAll(componentName,dataArray){
		var objectArray = ArrayNew(1);
		for(var i = 1; i <= ArrayLen(dataArray); i++){
			var object = dispense(arguments.componentName);
			object._import(dataArray[i]);
			arrayAppend(objectArray,object);
		}
		return objectArray;
	}

/////* Private functions *////////////////////////////////////////////////////////////////////

	private function create(object){
		var primaryKey = arguments.object.primaryKey;
		var columns = arguments.object.tableColumns;
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.object.componentName);
		var columnsList = "";
		var valuesList = "";
		for(var i = 1; i <= ArrayLen(columns); i++){
			var columnName = columns[i];
			var value = Evaluate("arguments.object.get#columnName#()");
			if(len(trim(value))){
				columnsList = listAppend(columnsList,"[#columnName#]");
				valuesList = listAppend(valuesList, "'#value#'");
			}			
		}
		results = queryService.execute(sql="INSERT INTO #arguments.object.componentName# (#columnsList#) OUTPUT inserted.#primaryKey# VALUES (#valuesList#)");
		var records = results.getResult();
		return records[primaryKey][1];
	}

	private function update(object){
		var primaryKey = arguments.object.primaryKey;
		var primaryKeyValue = Evaluate("object.get#primaryKey#()");
		var columns = arguments.object.tableColumns;
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.object.componentName);
		var updateList = "";
		for(var i = 1; i <= ArrayLen(columns); i++){
			var columnName = columns[i];
			var value = Evaluate("arguments.object.get#columnName#()");
			if(len(trim(value)) && columnName != primaryKey){
				updateList = listAppend(updateList,"[#columnName#]='#value#'");
			}			
		}
		results = queryService.execute(sql="UPDATE #arguments.object.componentName# SET #updateList# WHERE [#primaryKey#] = '#primaryKeyValue#'");

		return primaryKeyValue;
	}

	private function whereQuery(componentName, where, values){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.componentName);
		for(var i = 1; i <= ArrayLen(arguments.values); i++){
			queryService.addParam(value=arguments.values[i]);
		}
		results = queryService.execute(sql="SELECT * FROM #arguments.componentName# WHERE #arguments.where#"); 
		return results.getResult();
	}

	private function populateObject(object, records, iterator = 1){
		for(var i = 1; i <= ListLen(records.columnList); i++){
			var column = ListGetAt(records.columnList,i);
			var value = records[column][iterator];
			if(value!="")
				Evaluate("object.set#column#(value)");
		}
		return object;
	}

	private function getTableInfo(componentName){
		var dbschema = new dbinfo(datasource=variables.dataSource,table=arguments.componentName);
		return dbschema;
	}

	private function getPrimaryKey(componentName){
		var dbschema = getTableInfo(componentName);
		var columns = dbschema.columns();
		var primaryKey = "";
		for(var i = 1; i <= columns.recordcount; i++){
			if(columns["IS_PRIMARYKEY"][i]){
				primaryKey = columns["COLUMN_NAME"][i];
			}
		}
		return primaryKey;
	}

	private function getColumns(componentName){
		var dbschema = getTableInfo(componentName);
		var columns = dbschema.columns();
		var columnArray = ArrayNew(1);
		for(var i = 1; i <= columns.recordcount; i++){
			arrayAppend(columnArray,columns["COLUMN_NAME"][i]);	
		}
		return columnArray;
	}

	private function queryThis(queryString){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		var results = queryService.execute(sql=arguments.queryString); 
		return results;
	}


}