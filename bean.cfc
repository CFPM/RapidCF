/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RedBeanCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

component {
	
	function init(){
		variables.owns = {};
		return this;
	}

	public function onMissingMethod(MissingMethodName, MissingMethodArguments){
		if(Find("import", arguments.MissingMethodName)){
			//We have to do this because import is a reserved word for ColdFusion
			return this._import(arguments.MissingMethodArguments[1],arguments.MissingMethodArguments[2]);
		}else if(left(arguments.MissingMethodName,3) == "own"){
			var ownArguments = {
				ownComponentName = Replace(arguments.MissingMethodName,"own",""),
				beanCol = len(trim(arguments.MissingMethodArguments[1])) ? arguments.MissingMethodArguments[1] : "",
				ownCol = len(trim(arguments.MissingMethodArguments[2])) ? arguments.MissingMethodArguments[2] : "",
				beans = structKeyExists(arguments.missingMethodArguments,"3") ? arguments.missingMethodArguments[3] : []
			};
			return own(argumentCollection=ownArguments);
		}else{
			var params = "";
			for(param in MissingMethodArguments){
				listAppend(params,"'#param#'");
			}
			return Evaluate("this._info.model.#MissingMethodName#(#params#)");
		}
	}

	public function loadModel(modelName){
		this._info.model = new "#modelName#"(this);
	}

	public function export(keys=[]){
		var output = exportScope(this, keys);
		structAppend(output, exportScope(variables.owns, keys), false);
		return output;
	}

	private function exportScope(required scope, required array keys){
		var output = {};

		if(arrayIsEmpty(arguments.keys)){
			arguments.keys = listToArray(structKeyList(scope));
		}

		for(var key in arguments.keys){
			if(NOT structKeyExists(scope, key)){
				continue;
			}
			if(NOT isExportableKey(key)){
				continue;
			}

			if(IsInstanceOf(scope[key],"bean")){
				output[key] = scope[key].export();
			}
			else if(isArray(scope[key]) && arrayLen(scope[key]) > 0 && IsInstanceOf(scope[key][1],"bean")){
				output[key] = arrayNew(1);
				for(var i = 1; i <= arrayLen(scope[key]); i++){
					output[key][i] = scope[key][i].export();
				}
			}
			else{
				output[key] = scope[key];
			}
		}

		return output;
	}

	private function isExportableKey(required string key){
		return 	key != "THIS" && 
						key != "KEY" && 
						left(key, 1) != "_" &&
						!isFunction(key);
	}

	public function _import(data,keys=[]){
		if(ArrayLen(keys)>0){
			for(var key in keys){
				if(structKeyExists(data,key)){
					this[key] = data[key];
				}
			}
		}else{
			for(var key in data){
				this[key] = data[key];
			}
		}
		return this;
	}

	private function own(ownComponentName,beanCol="",ownCol="", beans){
		var ownBeans = this._rb.own(this,ownComponentName,beanCol,ownCol,beans);
		variables.owns[arguments.ownComponentName] = ownBeans;
		return ownBeans;
	}

	private boolean function isFunction(str){
		if(ListFindNoCase(StructKeyList(GetFunctionList()),str)){
			return true;
		}
		if(IsDefined(str) AND Evaluate("IsCustomFunction(#str#)")){
			return true;
		}
		return false;
	}

	public function setPrimaryKey(required primaryKey){
		this[getPrimaryKeyName()] = arguments.primaryKey;
		cascadePrimaryKey();
	}

	public function getPrimaryKeyValue(){
		return this[getPrimaryKeyName()];
	}

	public function getPrimaryKeyName(){
		return this._info.primaryKey;
	}

	private function cascadePrimaryKey(){
		cascadeKey(getPrimaryKeyName(), getPrimaryKeyValue());
	}

	public function cascadeKey(required string key, required value){
		for(var ownName in variables.owns){
			var beans = owns[ownName];
			for(var bean in beans){
				bean[key] = value;
				bean.cascadeKey(key, value);
			}
		}
	}

	public function cascadeSave(){
		for(var ownName in variables.owns){
			this._rb.storeAll(variables.owns[ownName]);
		}
	}
	public function isSaved(){
		var primaryKeyName = getPrimaryKeyName();
		return isDefined("this.#primaryKeyName#") && len(trim(this[primaryKeyName]));
	}

	public function null(columnName){
		structDelete(this, columnName);
		arrayAppend(this._info.nulledColumns,columnName);
	}
}