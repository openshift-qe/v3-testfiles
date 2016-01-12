ursor=db.getCollectionNames();
for(i=0;i<cursor.length;i++)
{
 //printjson(cursor[i]);
 //var db=connect(db);
var curU=cursor[i];
 if("system.indexes" == cursor[i] || "system.profile" == cursor[i])
 {
  print("find system");
 }
 else
 {  
  var whbC=db.getCollection(curU).count();
  var tmp=cursor[i]+"=="+whbC
  printjson(tmp);
  
  db.getCollection(cursor[i]).ensureIndex({"CreateTime":1});
 }
}

