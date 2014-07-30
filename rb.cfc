/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RedBeanCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

component {

	public function init(){
		return this;
	}

	public function setup(required string dataSource, string modelMapping = "/"){
		variables.dataSource = arguments.dataSource;
		variables.modelMapping = arguments.modelMapping;
		variables.modelPath = expandPath(modelMapping);
		variables.modelPathDir = DirectoryList(modelPath,true);
	}

	public function dispense(required string componentName){
		var bean = new bean();
		bean._info = {};
		bean._info.cache = {};
		bean._info.componentName = componentName;

		if(!isDefined("bean._info.tableName")){
			bean._info.tableName = arguments.componentName;
		}
		
		try{
			bean._info.tableColumns = getColumns(bean._info.tableName);
			bean._info.tableColumnTypes = getColumnTypes(bean._info.tableName);
			bean._info.primaryKey = getPrimaryKey(bean._info.tableName);
			bean._info.nulledColumns = [];
			for(var columnName in bean._info.tableColumns){
				bean._info.cache[columnName] = "";
			}
		}catch(any e){
			bean._info.tableColumns = [];
			bean._info.tableColumnTypes = {};
			bean._info.primaryKey = "";
			bean._info.nulledColumns = [];
		}
		loadModel(bean);
		bean._rb = this;
		return bean;
	}

	public function load(required string componentName, required any ID){
		var bean = dispense(arguments.componentName);
		var primaryKey = bean.getPrimaryKeyName();
		return findOne(arguments.componentName,"#primaryKey# = ? ",[id]);
	}

	public function findOne(required string componentName, required string where, required array values){
		var bean = dispense(arguments.componentName);
		var records = whereQuery(bean, where, values);
		if(records.recordcount > 0){
			return populatebean(bean,records);
		}else{
			return;
		}
	}

	public function find(required string componentName, string where="", array values=[]){
		var bean = dispense(arguments.componentName);
		var records = whereQuery(bean, arguments.where, arguments.values);
		var allbeans = [];
		for(var i = 1; i <= records.recordcount; i++){
			var bean = dispense(arguments.componentName);
			bean = populatebean(bean, records, i);
			arrayAppend(allbeans,bean);
		}
		return allbeans;	
	}

	public function store(beans){
		if(isArray(beans)){
			storeAll(beans);
		}else{
			save(beans);
		}			
	}

	public void function storeAll(required array beans){
		for(var bean in beans){
			store(bean);
		}
	}

	public void function trash(required bean){
		var primaryKey = arguments.bean.getPrimaryKeyName();
		if(len(trim(primaryKey))){
			var primaryKeyValue = bean[primaryKey];
			var queryService = new query();
			queryService.setDatasource(variables.dataSource); 
			queryService.setName(arguments.bean._info.tableName);
			var results = queryService.execute(sql="DELETE FROM [#arguments.bean._info.tableName#] WHERE [#primaryKey#] = '#primaryKeyValue#'"); 
		}
	}

	public function query(required string componentName, required string queryString, array params = []){
		var results = queryThis(arguments.queryString,params);
		var records = results.getResult();
		var bean = dispense(arguments.componentName);
		return populatebean(bean, records);
	}

	public function queryAll(required string componentName, required string queryString, array params = []){
		var results = queryThis(queryString,params);
		var records = results.getResult();
		var allbeans = [];
		for(var i = 1; i <= records.recordcount; i++){
			var bean = dispense(arguments.componentName);
			bean = populatebean(bean, records, i);
			arrayAppend(allbeans,bean);
		}
		return allbeans;
	}

	public function exportAll(required array beans){
		var exportArray = [];
		for(var bean in beans){
			arrayAppend(exportArray,bean.export());
		}
		return exportArray;
	}

	public function importAll(required string componentName, required array dataArray){
		var beanArray = [];
		for(var data in dataArray){
			var bean = dispense(arguments.componentName);
			bean.import(data);
			arrayAppend(beanArray,bean);
		}
		return beanArray;
	}

	public function own(bean, ownComponentName, beanCol="", ownCol="", beans){
		if(len(trim(arguments.beanCol))){
			var referenceKeyID = bean[arguments.beanCol];
		}else{
			var referenceKeyID = bean.getPrimaryKeyValue();
		}

		if(!len(trim(arguments.ownCol))){
			arguments.ownCol = bean._info.componentName & bean.getPrimaryKeyName();
		}

		if(isObject(arguments.beans)){
			arguments.beans = [arguments.beans];
		}

		if(NOT arrayIsEmpty(beans)){
			var ownBeans = arguments.beans;
		}else if(len(trim(referenceKeyID))){
			var ownBeans = this.find(arguments.ownComponentName,ownCol &  " = ?",[referenceKeyID]);
		}else{
			var ownBeans = [];
		}
		return ownBeans;
	}

	/*
	 * Private functions
	 */

	private function save(required bean){
		if(bean.isSaved()){
			update(bean);
		}else{
			create(bean);
		}
		bean.cascadeSave();
	}

	private function create(required bean){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.bean._info.tableName);

		var columnsList = "";
		var valuesList = "";
		
		var data = arguments.bean.export();
		
		for(var columnName in arguments.bean._info.tableColumns){
			if(structKeyExists(data,"#columnName#") && data[columnName]!=""){
				columnsList = listAppend(columnsList," [#columnName#] ");
				valuesList = listAppend(valuesList, " :#columnName# ");
				queryService.addParam(name=columnName,value=data[columnName],cfsqltype=getSQLType(arguments.bean._info.tableColumnTypes[columnName]));
			}
		}
		var primaryKey = arguments.bean.getPrimaryKeyName();

		// Trigger Safe Output workaround.  http://stackoverflow.com/questions/13198476/cannot-use-update-with-output-clause-when-a-trigger-is-on-the-table
		var results = queryService.execute(sql="
					DECLARE @inserted table (#primaryKey# varchar(max))

					INSERT [#arguments.bean._info.tableName#] (#columnsList#)
					OUTPUT inserted.#primaryKey#
					INTO @inserted
					VALUES (#valuesList#)

					SELECT #primaryKey# FROM @inserted
				");
		var records = results.getResult();

		bean.setPrimaryKey(records[primaryKey][1]);
	}

	private function update(required bean){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.bean._info.tableName);

		var primaryKey = arguments.bean.getPrimaryKeyName();
		var primaryKeyValue = bean[primaryKey];
		
		var updateList = "";

		var data = arguments.bean.export();
		for(var columnName in arguments.bean._info.tableColumns){
			if(structKeyExists(data,"#columnName#") && columnName != primaryKey){
				if(arguments.bean._info.cache[columnName] != data[columnName]){
					arguments.bean._info.cache[columnName] = data[columnName];
					queryService.addParam(name=columnName,value=data[columnName],cfsqltype=getSQLType(arguments.bean._info.tableColumnTypes[columnName]));
					updateList = listAppend(updateList," [#columnName#] = :#columnName# ");
				}
			}			
		}
		for(var columnName in arguments.bean._info.nulledColumns){
			updateList = listAppend(updateList," [#columnName#] = NULL ");
		}
		if(updateList != ""){
			var results = queryService.execute(sql="UPDATE [#arguments.bean._info.tableName#] SET #updateList# WHERE [#primaryKey#] = '#primaryKeyValue#'");
		}
	}	

	private function whereQuery(required bean, string where="", array values = []){
		if(!len(trim(where))){
			where = " 1=1 ";
		}
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		queryService.setName(arguments.bean._info.tableName);
		for(var value in values){
			queryService.addParam(value=value);
		}
		var results = queryService.execute(sql="SELECT * FROM [#arguments.bean._info.tableName#] WHERE #arguments.where#"); 
		return results.getResult();
	}

	private function populatebean(required bean, required records, required iterator = 1){
		bean._info.cache = {};
		for(var i = 1; i <= ListLen(records.columnList); i++){
			var column = ListGetAt(records.columnList,i);
			var value = records[column][iterator];
			if(value!=""){
				bean[column] = value;
			}
			bean._info.cache[column] = value;
		}
		if(isDefined("bean._info.model") && structKeyExists(bean._info.model,"onPopulate")){
			bean._info.model.onPopulate();
		}
		return bean;
	}

	private function queryThis(required string queryString, array params = []){
		var queryService = new query();
		queryService.setDatasource(variables.dataSource); 
		for(param in params){
			queryService.addParam(value=param);
		}
		var results = queryService.execute(sql=arguments.queryString); 
		return results;
	}

	private function getDefaultModelName(componentName){
		var modelName = componentName & "Model.cfc";
		for(var file in variables.modelPathDir){
			if(ListLast(file,"/\")==modelName){
				file = Replace(file,variables.modelPath, listFirst(variables.modelMapping,"/"));
				file = Replace(file,"/",".","ALL");
				file = Replace(file,"\",".","ALL");
				file = Replace(file,".cfc","");
				return file;
			}
		}
		return;
	}

	private function loadModel(bean){
		var modelName = getDefaultModelName(bean._info.tableName);
		if(isDefined("modelName")){
			bean._info.model = new "#modelName#"();
			bean._info.model.bean = bean;
		}
	}

	/*
	 * Database helpers
	 */

	public function getTableInfo(required string tableName){
		var dbschema = new dbinfo(datasource=variables.dataSource,table=arguments.tableName);
		return dbschema;
	}

	private function getPrimaryKey(required string tableName){
		var dbschema = getTableInfo(tableName);
		var columns = dbschema.columns();
		var primaryKey = "";
		for(var i = 1; i <= columns.recordcount; i++){
			if(columns["IS_PRIMARYKEY"][i]){
				primaryKey = columns["COLUMN_NAME"][i];
			}
		}
		return primaryKey;
	}

	private function getColumns(required string tableName){
		var dbschema = getTableInfo(tableName);
		var columns = dbschema.columns();
		var columnArray = [];
		for(var i = 1; i <= columns.recordcount; i++){
			arrayAppend(columnArray,columns["COLUMN_NAME"][i]);	
		}
		return columnArray;
	}

	private function getColumnTypes(required string tableName){
		var dbschema = getTableInfo(tableName);
		var columns = dbschema.columns();
		var columnTypeStruct = {};
		for(var i = 1; i <= columns.recordcount; i++){
			columnTypeStruct[columns["COLUMN_NAME"][i]] = columns["TYPE_NAME"][i];
		}
		return columnTypeStruct;
	}

	private function getSQLType(required string type){
		switch(type){
			case "bigint": return "CF_SQL_BIGINT"; break;
			case "bit": return "CF_SQL_BIT"; break;
			case "date": return "CF_SQL_DATE"; break;
			case "datetime": return "CF_SQL_TIMESTAMP"; break;
			case "decimal": return "CF_SQL_DECIMAL"; break;
			case "float": return "CF_SQL_FLOAT"; break;
			case "int": return "CF_SQL_INTEGER"; break;
			case "varchar": return "CF_SQL_VARCHAR"; break;
			case "timestamp": return "CF_SQL_TIMESTAMP"; break;
			default: return "CF_SQL_VARCHAR"; break;
		} 
	}
}
