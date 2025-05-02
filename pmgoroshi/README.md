# pmgoroshi

A new Flutter project.

function fn_save(){
gfn_loading(true);

    var type = "POST";
    var url = "/mobile/report/reportSave.do";
    var param = new Object();

    param.useUrl = gfn_nullvalue($("#useUrl").val(), "");
    param.quickId = gfn_nullvalue($("#quickId").val(), "");
    param.lat = gfn_nullvalue($("#lat").val(), "");
    param.lng = gfn_nullvalue($("#lng").val(), "");
    param.memo = gfn_nullvalue($("#memo").val(), "");
    param.pass = gfn_nullvalue($("#pass").val(), "");
    param.agreeYn = $("#agreeChk").is(":checked") == true ? "Y" : "N";
    param.addr = gfn_nullvalue($("#address").val(), "");
    //param.emCd = $("#emerChk").is(":checked") == true ? "Y" : "N";
    param.vltCd = $("input[name=r_violation]:checked").val();

}
