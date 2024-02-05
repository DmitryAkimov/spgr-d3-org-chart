const ODATA_1C = {
    "DO" : {
        "root" : "https://m1c-1.spgr.ru/do/odata/standard.odata/",
        //"auth" : basicAuth("webreader", "webreader"),
    } ,
}
const url = "http://m1c-1/1c-zup-uu-odata/odata/standard.odata//Catalog_СтруктураПредприятия?%24format=json&%24select=Ref_Key%2CParent_Key%2CDescription%2CCode&%24orderby=Parent_Key&%24filter=DeletionMark%20eq%20false";
const credentials = btoa('webreader:webreader') ;// change to yours
const auth = { "Authorization" : `Basic ${credentials}` } ;
const username = "webreader";
const password = "webreader";
(async () => {
    let response = await fetch(url, { 
        mode:  'no-cors' ,
        method: 'GET',
        //credentials: 'include',
        headers : new Headers ({ 
            "Authorization" : "Basic d2VicmVhZGVyOndlYnJlYWRlcg==",
            "accept" : 'application/json', 
        })

    } );

    if (response.ok) { // если HTTP-статус в диапазоне 200-299
      // получаем тело ответа (см. про этот метод ниже)
      let json = await response.json();
      console.log(json);
    } else {
      alert("Ошибка HTTP: " + response.status);
    }  })();
