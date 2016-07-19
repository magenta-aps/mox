var pollJob = function(jobId, callback) {
    if (jobId && callback) {
        var poller = setInterval(function(){
            $.get({
                url: "status",
                data: {'jobId': jobId},
                dataType: "json",
                success: function(responseObject, status, jqXHR){
                    if (responseObject && 'response' in responseObject) {
                        var serviceResponse = responseObject.response;
                        if (typeof(serviceResponse)=="string") {
                            try {
                                serviceResponse = JSON.parse(serviceResponse);
                            } catch (e) {}
                        }
                        if (typeof(serviceResponse)=="object") {
                            callback(serviceResponse);
                        }
                        clearInterval(poller);
                        poller = null;
                    }
                },
                error: function(){
                    clearInterval(poller);
                    poller = null;
                }
            });
        }, 1000);
    }
};