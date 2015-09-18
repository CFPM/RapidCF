/*
 * Any changes should be made and pushed to here: https://github.com/Prefinem/RedBeanCF
 * Author: William Giles
 * License: MIT http://opensource.org/licenses/MIT
 */

 component {

    function init() {
        return this;
    }

    function createTables(){
        queryService = new query();
        queryService.setDatasource(variables.dataSource);
        result = queryService.execute(sql="
            IF object_id('[user]') IS NOT NULL
                DROP TABLE [user]

            CREATE TABLE [user](
                [id] [int] IDENTITY(1,1) NOT NULL,
                [firstName] [varchar](50) NOT NULL,
                [lastName] [varchar](50) NOT NULL,
                [email] [varchar](50) NULL,
            CONSTRAINT [PK_contacts] PRIMARY KEY CLUSTERED 
            (
                [id] ASC
            )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
            ) ON [PRIMARY]

        ");
        result = queryService.execute(sql="
            IF object_id('[message]') IS NOT NULL
                DROP TABLE [message]

            CREATE TABLE [message](
                [id] [int] IDENTITY(1,1) NOT NULL,
                [userID] [int] NOT NULL,
                [userIDCreator] [int] NOT NULL,
                [text] [varchar](max) NULL,
            CONSTRAINT [PK_messages] PRIMARY KEY CLUSTERED 
            (
                [id] ASC
            )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
            ) ON [PRIMARY]
        ");
    }

    function setupORM(){
        variables.ORM = CreateObject("component","common.CFC.com.RedBeanCF.rb");
        variables.ORM.setup(variables.dataSource);
    }

    function tearDown(){
        queryService = new query();
        queryService.setDatasource(variables.dataSource);
        result = queryService.execute(sql="
            IF object_id('[user]') IS NOT NULL
                DROP TABLE [user]
        ");
        result = queryService.execute(sql="
            IF object_id('[message]') IS NOT NULL
                DROP TABLE [message]
        ");     
    }

    function startTests(dataSource){
        
        variables.dataSource = arguments.dataSource;

        setupORM();
        createTables();
        
        createUsers();
        testUserCreation();
        
        editUsers();
        testUserEdit();

        deleteUsers();
        testUserDeletion();

        createUsers();
        createMessages();

        testOneToMany();
        testManyToMany();

        testFullName();

        tearDown();

        writeDump("Tests were successful");
    }


    function createUsers(){
        var user1 = variables.ORM.dispense("user");
        var user2 = variables.ORM.dispense("user");

        user1.FirstName = "John";
        user1.LastName = "Doe";
        user1.Email = "john.doe@gmail.com";
        variables.ORM.store(user1);
        
        var user2Struct = {
            firstName = "Jane",
            lastName = "Doe",
            email = "jane.doe@gmail.com"
        };
        user2.import(user2Struct);
        variables.ORM.store(user2);

    }

    function createMessages(){
        var user1 = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["John","Doe"]);
        var user2 = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["Jane","Doe"]);

        var message = variables.ORM.dispense("message");
        message.text = "Hello John Doe";
        message.UserID = user1.ID;
        message.UserIDCreator = user2.ID;

        variables.ORM.store(message);

        var message = variables.ORM.dispense("message");
        message.Text = "Hi Jane";
        message.UserID = user2.ID;
        message.UserIDCreator = user1.ID;
        variables.ORM.store(message);
        
        var message = variables.ORM.dispense("message");
        message.Text = "How are you?";
        message.UserID = user1.ID;
        message.UserIDCreator = user2.ID;
        variables.ORM.store(message);

    }

    function testUserCreation(){
        queryService = new query();
        queryService.setDatasource(variables.dataSource);
        queryService.setName("user");
        queryService.addParam(value="John",cfsqltype="cf_sql_varchar");
        queryService.addParam(value="Doe",cfsqltype="cf_sql_varchar");
        result = queryService.execute(sql="SELECT * FROM [user] WHERE firstName = ? AND lastName = ? ");
        records = result.getResult();
        if(records.recordCount != 1)
            throw "ERROR: Failed to retrieve First User. rb.store() isn't working";

        queryService = new query();
        queryService.setDatasource(variables.dataSource);
        queryService.setName("user");
        queryService.addParam(value="Jane",cfsqltype="cf_sql_varchar");
        queryService.addParam(value="Doe",cfsqltype="cf_sql_varchar");
        result = queryService.execute(sql="SELECT * FROM [user] WHERE firstName = ? AND lastName = ? ");
        records = result.getResult();
        if(records.recordCount != 1)
            throw "ERROR: Failed to retrieve First User. rb.store() isn't working";
        
    }

    function editUsers(){
        var user = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["John","Doe"]);
        user.Email = "john.doe@yahoo.com";
        variables.ORM.store(user);
    }
    
    function testUserEdit(){
        queryService = new query();
        queryService.setDatasource(variables.dataSource);
        queryService.setName("user");
        queryService.addParam(value="John",cfsqltype="cf_sql_varchar");
        queryService.addParam(value="Doe",cfsqltype="cf_sql_varchar");
        result = queryService.execute(sql="SELECT * FROM [user] WHERE firstName = ? AND lastName = ? ");
        records = result.getResult();
        if(records.recordCount != 1)
            throw "ERROR: Failed to retrieve First User. User isn't in table";

        if(records.email[1] != "john.doe@yahoo.com")
            throw "ERROR: Failed to update First User. rb.store() isn't working";
    }

    function deleteUsers(){
        var user1 = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["John","Doe"]);
        variables.ORM.trash(user1);
        var user2 = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["Jane","Doe"]);
        variables.ORM.trash(user2);
    }

    function testUserDeletion(){
        queryService = new query();
        queryService.setDatasource(variables.dataSource);
        queryService.setName("user");
        result = queryService.execute(sql="SELECT * FROM [user]");
        records = result.getResult();
        if(records.recordCount != 0)
            throw "ERROR: Failed to delete users";
    }

    function testFind(){
        var users = variables.ORM.find("user");
        if(arrayLen(users) != 2)
            throw "ERROR: Failed to find all users";
    }

    function testOneToMany(){
        var user = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["John","Doe"]);
        var userMessages = user.ownMessage();

        if(arrayLen(userMessages)!=2)
            throw "ERROR: Failed to grab all messages of one user";
    }

    function testManyToMany(){
        var user = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["John","Doe"]);
        var userCreated = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["Jane","Doe"]);
        var message = variables.ORM.findOne("message","userID = ?",[user.ID]);

        var messageUser = message.ownUser("userID","ID");
        var messageUserCreated = message.ownUser("userIDCreator","ID");

        if(messageUser[1].ID != user.ID)
            throw "ERROR: Did not get the correct user for lazy loading";

        if(messageUserCreated[1].ID != userCreated.ID)
            throw "ERROR: Did not get the correct userCreated for lazy loading";
    }

    function testFullName(){
        var user = variables.ORM.findOne("user","firstName = ? AND lastName = ?",["John","Doe"]);
        user.loadModel("common.CFC.com.RedBeanCF.tests.UserRBTestModel");
        if(user.getFullName() != "John Doe")
            throw "ERROR: Model is not working";
    }

}