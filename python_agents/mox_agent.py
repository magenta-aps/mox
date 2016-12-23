import pika

from settings import AMQP_SERVER


class MOXAgent(object):
    """Super class for MOX agents written in Python."""

    exchange = None
    queue = None
    do_persist = False

    def callback(self, ch, method, properties, body):
        """Generic callback function for MOX agents."""
        # TODO: Maybe always do SAML authentication here.
        pass

    def run(self):
        """Main program - wait and listen to queue."""
        if not self.queue:
            print "Please specify queue before running!"
            return
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host=AMQP_SERVER)
        )
        channel = connection.channel()

        channel.queue_declare(queue=self.queue,
                              durable=self.do_persist)

        print ' [*] Waiting for messages. To exit press CTRL+C'

        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(self.callback,
                              queue=self.queue,
                              no_ack=True)

        channel.start_consuming()


class TestAgent(MOXAgent):
    """Simple test class to check that the basic AMQP transport works."""

    queue = 'agent_test'

    def callback(self, ch, method, properties, body):
        """Simple test case - just print input to stdout."""
        print "**********************************************"
        print body
        print "**********************************************"


if __name__ == '__main__':
    agent = TestAgent()
    agent.run()
