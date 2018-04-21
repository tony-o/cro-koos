(function($){
  var input       = $("input#search-terms");
  var results_ui  = $("span#result_count");
  var query_ui    = $("span#query");
  var tbl         = $(".table-body");
  var tbl_factory = $(".table-row-template");


  tbl_factory.hide();
  tbl_factory = tbl_factory.clone().removeClass("table-row-template");
  var fill_table = function(query, data){
    query_ui.text(query);
    results_ui.text(data.results);
    var meta = data['meta-list'];
    tbl.empty();
    for(var i in meta){
      var row = tbl_factory.clone();
      row.find(".name").text(meta[i].name);
      row.find(".version").text(meta[i].version);
      row.find(".auth").text(meta[i].auth);
      row.find(".api").text(meta[i].api);
      row.find(".source").html("<a target=\"_new\" href=\"" + meta[i]['source-url'].replace('git://', 'https://') + "\">"+meta[i]['source-url']+"</a>");
      row.show();
      tbl.append(row);
    }
    $(".hide-until-search").show();
  };

  var do_search  = function(){
    var query = { };
    var val   = input.val();
    var split = val.match(/:ver<(.*?)>|:auth<(.*?)>|:api<(.*?)>/g);
    query.name = val;
    for(var i in split){
      query[split[i].substr(1, split[i].indexOf('<')-1)] = split[i].substr(split[i].indexOf('<')+1, split[i].length-2-split[i].indexOf('<'));
      query.name = query.name.replace(split[i], '');
    }
    $.ajax({
      url: '/candidates',
      data: JSON.stringify(query),
      method: 'POST',
      contentType: 'application/json',
      dataType: 'json',
      success: function(){
        fill_table(val, arguments[0]);
      }
    });
  };

  input.blur(do_search);
})($);
