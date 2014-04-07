/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RedBeanCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

component {

	public function init(){
		return this;
	}

	public function setup(required string dataSource){
		variables.dataSource = arguments.dataSource;
	}

	public function dispense(required string componentName){
		try{
			var object = new "#componentName#"();
		}catch(any e){
			var object = new rbEntity();		
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

	public function load(required string componentName, required any ID){
		var primaryKey = getPrimaryKey(componentName);
		return this.find(arguments.componentName,"#primaryKey# = ? ",[id]);
	}

	public function find(required string componentName,where,values){
		var object = dispense(arguments.componentName);
		var records = whereQuery(componentName, where, values);
		if(records.recordcount > 0)
			return populateObject(object,records);
		else
			return false;
	}

	public function findAll(required string componentName,required string where,required array values){
		var records = whereQuery(componentName, where, values);
		var allObjects = arrayNew(1);
		for(var i = 1; i <= records.recordcount; i++){
			var object = dispense(arguments.componentName);
			object = populateObject(object, records, i);
			arrayAppend(allObjects,object);
		}
		return allObjects;	
	}

	public function store(required object){
		var primaryKey = arguments.object.primaryKey;
		var primaryKeyValue = Evaluate("object.get#primaryKey#()");
		if(len(trim(primaryKey))){
			if(len(trim(primaryKeyValue))){
				update(arguments.object);
			}else{
				create(arguments.object);
			}
		}
	}

	public void function storeAll(required array objects){
		for(var object in objects){
			store(object);
		}
	}

	public void function trash(required object){
		var primaryKey = arguments.object.primaryKey;
		if(len(trim(primaryKey))){
			transaction{
				var primaryKeyValue = Evaluate("object.get#primaryKey#()");
				var queryService = new query();
				queryService.setDatasource(variables.dataSource); 
				queryService.setName(arguments.object.componentName);
				results = queryService.execute(sql="DELETE FROM [#arguments.object.componentName#] WHERE [#primaryKey#] = '#primaryKeyValue#'"); 
			}
		}
	}

	public function query(required string componentName, required string queryString, array params = ArrayNew(1)){
		var results = queryThis(arguments.queryString,params);
		var records = results.getResult();
		var object = dispense(arguments.componentName);
		return populateObject(object, records);
	}

	public function queryAll(required string componentName, required string queryString, array params = ArrayNew(1)){
		var results = queryThis(queryString,params);
		var records = results.getResult();
		var allObjects = arrayNew(1);
		for(var i = 1; i <= records.recordcount; i++){
			var object = dispense(arguments.componentName);
			object = populateObject(object, records, i);
			arrayAppend(allObjects,object);
		}
		return allObjects;
	}

	public function exportAll(required array objects){
		var exportArray = ArrayNew(1);
		for(var object in objects){
			arrayAppend(exportArray,object._export());
		}
		return exportArray;
	}

	public function importAll(required string componentName, required array dataArray){
		var objectArray = ArrayNew(1);
		for(var data in dataArray){
			var object = dispense(arguments.componentName);
			object._import(data);
			arrayAppend(objectArray,object);
		}
		return objectArray;
	}

/*
 * Private functions
 */

	private function create(required object){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.object.componentName);

		var columnsList = "";
		var valuesList = "";
		
		var data = arguments.object._export();
		
		for(var columnName in arguments.object.tableColumns){
			if(structKeyExists(data,"#columnName#")){
				queryService.addParam(value=data[columnName]);
				columnsList = listAppend(columnsList,"[#columnName#]");
				valuesList = listAppend(valuesList, " ? ");
			}
		}
		results = queryService.execute(sql="INSERT INTO [#arguments.object.componentName#] (#columnsList#) OUTPUT inserted.#arguments.object.primaryKey# VALUES (#valuesList#)");
		var records = results.getResult();
		variables[arguments.object.primaryKey] = records[arguments.object.primaryKey][1];
	}

	private function update(required object){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.object.componentName);
		
		var updateList = "";

		var data = arguments.object._export();
		for(var columnName in arguments.object.tableColumns){
			if(structKeyExists(data,"#columnName#") && columnName != arguments.object.primaryKey){
				queryService.addParam(name=columnName,value=data[columnName]);
				updateList = listAppend(updateList," [#columnName#] = :#columnName# ");
			}			
		}
		var primaryKeyValue = data[arguments.object.primaryKey];
		results = queryService.execute(sql="UPDATE [#arguments.object.componentName#] SET #updateList# WHERE [#arguments.object.primaryKey#] = '#primaryKeyValue#'");
	}	

	private function whereQuery(required string componentName, string where="", required array values){
		if(!len(trim(where)))
			where = "1=1";
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.componentName);
		for(var value in values){
			queryService.addParam(value=value);
		}
		results = queryService.execute(sql="SELECT * FROM [#arguments.componentName#] WHERE #arguments.where#"); 
		return results.getResult();
	}

	private function populateObject(required object, required records, required iterator = 1){
		for(var i = 1; i <= ListLen(records.columnList); i++){
			var column = ListGetAt(records.columnList,i);
			var value = records[column][iterator];
			if(value!="")
				Evaluate("object.set#column#(value)");
		}
		return object;
	}

	private function getTableInfo(required string componentName){
		var dbschema = new dbinfo(datasource=variables.dataSource,table=arguments.componentName);
		return dbschema;
	}

	private function getPrimaryKey(required string componentName){
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

	private function getColumns(required string componentName){
		var dbschema = getTableInfo(componentName);
		var columns = dbschema.columns();
		var columnArray = ArrayNew(1);
		for(var i = 1; i <= columns.recordcount; i++){
			arrayAppend(columnArray,columns["COLUMN_NAME"][i]);	
		}
		return columnArray;
	}

	private function queryThis(required string queryString, array params = ArrayNew(1)){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		for(param in params){
			queryService.addParam(value=param);
		}
		var results = queryService.execute(sql=arguments.queryString); 
		return results;
	}


}