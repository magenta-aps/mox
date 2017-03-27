import zlib
import base64
import pika

from settings import AMQP_SERVER, SAML_IDP_CERTIFICATE


def unpack_saml_token(token):
    """Retrieve the SAML XML from a gzipped auth header."""
    data = token.split(' ')[1]
    data = base64.b64decode(data)

    token = zlib.decompress(data, 15+16)

    return token


def get_idp_cert():
    try:
        with open(SAML_IDP_CERTIFICATE) as file:
            return file.read()
    except Exception:
        raise


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
        if not (self.queue or self.exchange):
            print "Please specify queue or exchange before running!"
            return
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host=AMQP_SERVER)
        )
        channel = connection.channel()

        result = channel.queue_declare(queue=self.queue,
                                       durable=self.do_persist)
        if self.exchange:
            channel.exchange_declare(exchange=self.exchange, type='fanout')
            channel.queue_bind(result.method.queue,
                               exchange=self.exchange)

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
