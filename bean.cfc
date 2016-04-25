/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RapidCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

component {

    function init(){
        this.owns = {};
        return this;
    }

    public function onMissingMethod(MissingMethodName, MissingMethodArguments){
        if(Find("import", arguments.MissingMethodName)){
            //We have to do this because import is a reserved word for ColdFusion
            return this._import(arguments.MissingMethodArguments[1],arguments.MissingMethodArguments[2]);
        }else if(left(arguments.MissingMethodName,3) == "own"){
            var ownArguments = {
                ownComponentName = Replace(arguments.MissingMethodName,"own",""),
                beanCol = structKeyExists(arguments.missingMethodArguments,"1") && len(trim(arguments.MissingMethodArguments[1])) ? arguments.MissingMethodArguments[1] : "",
                ownCol = structKeyExists(arguments.missingMethodArguments,"2") && len(trim(arguments.MissingMethodArguments[2])) ? arguments.MissingMethodArguments[2] : "",
                beans = structKeyExists(arguments.missingMethodArguments,"3") ? arguments.missingMethodArguments[3] : []
            };
            return own(argumentCollection=ownArguments);
        }else{
            if(structKeyExists(this._info, "model")){
                var params = "";
                if(arrayLen(MissingMethodArguments)>0){
                    for(i in MissingMethodArguments){
                        params = listAppend(params,"'#MissingMethodArguments[i]#'");
                    }
                    return Evaluate("this._info.model.#MissingMethodName#(#params#)");
                }else{
                    return Evaluate("this._info.model.#MissingMethodName#()");
                }
            }
        }
    }

    public function loadModel(modelName){
        this._info.model = new "#modelName#"();
        this._info.model.bean = this;
        if(structKeyExists(this._info.model, "onModelLoad")){
            this._info.model.onModelLoad();
        }
    }

    public function export(keys=[]){
        var output = {};
        var scope = arrayIsEmpty(arguments.keys) ? this : arguments.keys;
        for(var key in scope){
            // only export simple values.  bean.export is used to get the data of a bean for writing to the database or serializing.
            // do not modify this without serious performance evaluation
            if(isSimpleValue(this[key])){
                output[key] = this[key];
            }
        }
        return output;
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

    public function cascadeKey(required string key, required value){
        for(var ownName in this.owns){
            var beans = owns[ownName];
            for(var bean in beans){
                bean[key] = value;
                bean.cascadeKey(key, value);
            }
        }
    }

    public function cascadeSave(){
        for(var ownName in this.owns){
            this._rapid.storeAll(this.owns[ownName]);
        }
    }

    public function isSaved(){
        var primaryKeyName = getPrimaryKeyName();
        return structKeyExists(this, primaryKeyName) && len(trim(this[primaryKeyName]));
    }

    public function null(columnName){
        structDelete(this, columnName);
        this._data.nulledColumns[columnName] = true;
    }

    /*
     * Private functions
     */

    private function own(ownComponentName,beanCol="",ownCol="", beans){
        var ownBeans = this._rapid.own(this,ownComponentName,beanCol,ownCol,beans);
        this.owns[arguments.ownComponentName] = ownBeans;
        return ownBeans;
    }

    public void function ownBeans(required string ownComponentName, required beans){
        if(isObject(arguments.beans)){
            arguments.beans = [arguments.beans];
        }
        this.owns[ownComponentName] = arguments.beans;
    }

    private boolean function isFunction(str){
        if(ListFindNoCase(StructKeyList(GetFunctionList()),str)){
            return true;
        }
        if(structKeyExists(arguments, "str") AND Evaluate("IsCustomFunction(#str#)")){
            return true;
        }
        return false;
    }

    private function cascadePrimaryKey(){
        cascadeKey(getPrimaryKeyName(), getPrimaryKeyValue());
    }
}
