import pika
import uuid


class MoxRpcClient:
    connection = None
    channel = None
    callback_queue = None
    response = None
    corr_id = None

    def __init__(self):

        self.connection = pika.BlockingConnection(
            pika.ConnectionParameters('localhost')
        )
        self.channel = self.connection.channel()
        self.callback_queue = self.channel.queue_declare(
            '', False, False, True, False
        )
        self.channel.basic_consume(self.on_response, no_ack=True, 
                              queue=self.callback_queue.method.queue)

    
    def on_response(self, ch, method, props, body):
        if props.correlation_id == self.corr_id:
            print "RESPONSE:", body
	    self.response = body

    def call(self, headers):

        self.response = None
        self.corr_id = str(uuid.uuid4())
        self.channel.basic_publish(exchange='mox.rest',
                                   routing_key='',
                                   properties=pika.BasicProperties(
                                       reply_to=self.callback_queue.method.queue,
                                       correlation_id=self.corr_id,
                                       headers=headers
                                   ),
                                   body=''
                                  )
        while self.response is None:
            print "Inside while and processing."
            self.connection.process_data_events()
            print "Done processing!"
        return self.response


query = '{ "brugervendtnoegle": "%" }'
operation = "search"
objekttype = "Bruger"
headers = { 'query': query, "operation": operation, "objekttype": objekttype,
           "objektID": None } 
mox_rpc = MoxRpcClient() 
response = mox_rpc.call(headers) 
print response


