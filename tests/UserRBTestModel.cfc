/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RapidCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

component {

    function getFullName(){
        return this.bean.firstName & " " & this.bean.lastName;
    }

}