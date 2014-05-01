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
				componentName = Replace(arguments.MissingMethodName,"own",""),
				referenceKey = len(trim(arguments.MissingMethodArguments[1])) ? arguments.MissingMethodArguments[1] : "",
				referenceColumn = len(trim(arguments.MissingMethodArguments[2])) ? arguments.MissingMethodArguments[2] : "",
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

	private function own(componentName,referenceKey="",referenceColumn="", beans){
		if(len(trim(referenceKey))){
			if(len(trim(referenceColumn))){
				var referenceKeyID = this[arguments.referenceColumn];
			}else{
				var referenceKeyID = this[arguments.componentName & arguments.referenceKey];
			}
		}else{
			referenceKey = this._info.componentName & this._info.primaryKey;
			var referenceKeyID = this[this._info.primaryKey];
		}

		if(isObject(arguments.beans)){
			arguments.beans = [arguments.beans];
		}

		if(NOT arrayIsEmpty(beans)){
			variables.owns[arguments.componentName] = arguments.beans;
		}
		else if(len(trim(referenceKeyID))){
			variables.owns[arguments.componentName] = this._rb.find(arguments.componentName,referenceKey &  " = ?",[referenceKeyID]);
		}else{
			variables.owns[arguments.componentName] = [];
		}
		return variables.owns[arguments.componentName];
	}
	private function isFunction(str){
		if(ListFindNoCase(StructKeyList(GetFunctionList()),str)){
			return 1;
		}
		if(IsDefined(str) AND Evaluate("IsCustomFunction(#str#)")){
			return 1;
		}
		return 0;
	}

	public function setPrimaryKey(required primaryKey){
		this[getPrimaryKeyName()] = arguments.primaryKey;
		cascadePrimaryKey();
	}
	private function getPrimaryKeyValue(){
		return this[getPrimaryKeyName()];
	}
	private function getPrimaryKeyName(){
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
			var beans = owns[ownName];
			for(var bean in beans){
				this._rb.store(bean);
			}
		}
	}
	public function isSaved(){
		var primaryKeyName = getPrimaryKeyName();
		return isDefined("this.#primaryKeyName#") && 
					 len(trim(this[primaryKeyName]));
	}
}