"use strict";

var ENTER_KEY_CODE = 13;
var queryInput, resultDiv, suggestedInput;
var sessionid = Date.now();

function showLoading(node) {

    node.innerHTML = "<img src='images/load.png'  width='100px' height='50px' id='img'>";
    resultDiv.appendChild(node);
    scrollDownOnclick();
    setTimeout(function () {
        node.style.display = "none";
    }, 500);
}

function createQueryNode(query) {
    var node = document.createElement('div');
    node.classList.add("card-panel");
    node.innerHTML = query;
    node.style.float = "right";
    let d = document.createElement('div');
    d.style.width = '15px';
    d.style.clear = 'both';
    resultDiv.appendChild(node);
    resultDiv.appendChild(d);
    return node;
}

function createResponseNode(intent_name, lang) {
    var parentNode = document.createElement('div');
    var childNode = document.createElement('div');
    var date = new Date();
    var timestamp = date.getTime();
    var btn = document.createElement('button');
    btn.id = "infected" + timestamp;
    if (lang == "en") {
        btn.innerHTML = "I received a positive test result";
    }
    else {
        btn.innerHTML = "Recibí un resultado positivo";
    }

    var btn1 = document.createElement('button');
    btn1.id = "exposed" + timestamp;
    if (lang == "en") {
        btn1.innerHTML = "I received an exposure notification";
    }
    else {
        btn1.innerHTML = "Recibí una notificación de exposición";
    }

    var btn2 = document.createElement('button');
    btn2.id = "info" + timestamp;
    if (lang == "en") {
        btn2.innerHTML = "Find more information";
    }
    else {
        btn2.innerHTML = "Información Adicional";
    }

    btn.classList.add("btn-panel");
    btn1.classList.add("btn-panel");
    btn2.classList.add("btn-panel");

    btn.addEventListener('click',
        function () {
            cancelSuggestion(this, btn.id, btn1.id, btn2.id, lang)
        });

    btn1.addEventListener('click',
        function () {
            cancelSuggestion(this, btn.id, btn1.id, btn2.id, lang)
        }
    );

    btn2.addEventListener('click',
        function () {
            cancelSuggestion(this, btn.id, btn1.id, btn2.id, lang)
        }
    );
    var node = document.createElement('div');
    node.classList.add("card-panel");
    node.innerHTML = "...";
    parentNode.appendChild(node);
    parentNode.appendChild(childNode);
    childNode.appendChild(btn);
    childNode.appendChild(btn1);
    childNode.appendChild(btn2);
    resultDiv.appendChild(parentNode);
    if (intent_name == "Default Welcome Intent") {
        childNode.style.display = "block";
    }
    else {
        childNode.style.display = "none";
    }
    return node;
}

function setResponseOnNode(response1, node) {
    var response = response1[0];
    node.style.color = "#000000";
    var resp = "Sorry, I didn\'t get that. Here are a few things you might be looking for."
    if (response.indexOf("http://") != -1 || response.indexOf("https://") != -1) {
        var responseList = response.split(" ");
        var out = "";
        for (var i = 0; i < responseList.length; i++) {
            if (responseList[i].startsWith("http")) {
                var url = responseList[i];
                var linkResp = linkUrl(responseList[i], url);
                out = out + " " + linkResp;
            }
			else if(responseList[i].includes("local")){
				var output = "";
				output += "<a href='https://www.vdh.virginia.gov/health-department-locator' target='_blank'>local health department</a>";
				out= out + " " + output+ ",";
				i=i+3;
			}
			else if(responseList[i].includes("departamento")){
				var output = "";
				output += "<a href='https://www.vdh.virginia.gov/health-department-locator' target='_blank'>departamento de salud local</a>";
				out= out + " " + output;
				i=i+3;
            }
            else if(responseList[i].includes("FAQ")){
				var output = "";
				output += "<a href='http://www.covidwise.org/frequently-asked-questions' target='_blank'>FAQ.</a>";
				out= out + " " + output;
			}
            else {
					out = out + " " + responseList[i];
            }
        }
        node.innerHTML = out;
    }
    else {
        resp = response ? response : resp;
        node.innerHTML = resp;
    }
    if (response1[1] == "Default Welcome Intent - exposed" || response1[1] == "Default Welcome Intent - Infected" || response1[1] == "Default Welcome Intent - info" || response1[1] == "Default Fallback Intent") {
        var parentNode = document.createElement("div");
        var btn1 = document.createElement("button");
        btn1.id = "start";
        //node.appendChild(parentNode);
        resultDiv.appendChild(btn1);
        if (response1[2] == "en") {
            btn1.innerHTML = "Start over";
        }
        else {
            btn1.innerHTML = "Comenzar de nuevo";
        }

        btn1.classList.add("start-panel");
        btn1.addEventListener('click',
            function () {
                createQueryNode(btn1.innerHTML);
                btn1.style.display = "none";
                var Node1 = document.createElement('div');
                sendRequest("hola", sessionid, response1[2]).then(function (response) {
                    var out = response.split("###");
                    setTimeout(function () {
                        var responseNode = createResponseNode(out[1], out[2]);
                        setResponseOnNode(out, responseNode);
                        scrollDownOnclick();
                    }, 500);
                });
                showLoading(Node1);
            }
        );
    }
}

function cancelSuggestion(btnx, btn, btn1, btn2, lang) {
    var suggestInput = btnx.innerHTML
    createQueryNode(suggestInput);
    var parentNode = document.createElement('div');
    var btnid = document.getElementById(btn);
    var btnid1 = document.getElementById(btn1);
    var btnid2 = document.getElementById(btn2);
    btnid.style.display = 'none';
    btnid1.style.display = 'none';
    btnid2.style.display = 'none';
    sendRequest(suggestInput, sessionid, lang).then(function (response) {
        var out = response.split("###");
        setTimeout(function () {
            var responseNode = createResponseNode(out[1], out[2]);
            setResponseOnNode(out, responseNode);
            scrollDownOnclick();
        }, 500);
    });
    showLoading(parentNode);
}

function linkUrl(response, url) {
    var output = "";
    while (response.indexOf(url) >= 0) {
        output += response.substr(0, response.indexOf(url));
        response = response.substr(response.indexOf(url), response.length - response.indexOf(url));
        var l = response.indexOf(" ");
        if (response.indexOf("<") < l) l = response.indexOf("<");
        if (l < 0) l = response.length + 1;
        output += "<a href=\"" + response.substr(0, l - 1) + "\" target='_blank'>" + response.substr(0, l - 1) + "</a>";
        response = response.substr(l, response.length - l);
    }
    output += response;
    return output;
}

function sendRequest(value, sessionid, language_code) {
    var URL = "/get_intent_response?input_string=" + value + "&sessionid=" + sessionid + "&locale=" + language_code
    var xhttp = new XMLHttpRequest();
    xhttp.open("GET", URL, false);
    xhttp.send();
    var promise = new Promise(function (resolve, reject) {
        setTimeout(function () {
            var resp = xhttp.responseText;
            resolve(resp);
        }, 100);
    });
    return promise;
}

function init(language_code) {
    queryInput = document.getElementById("q");
    resultDiv = document.getElementById("result");
    suggestedInput = document.getElementById("suggest-input");
    sendRequest("hola", sessionid, language_code).then(function (response) {
        var out = response.split("###");
        var responseNode = createResponseNode(out[1], language_code);
        setResponseOnNode(out, responseNode);
    });

}

function scrollDownOnclick() {
    var objDiv = document.getElementById("ChattingSec");
    objDiv.scrollTop = objDiv.scrollHeight;
}
