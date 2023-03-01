
import java.util.Properties;

import javax.jms.Connection;
import javax.jms.Destination;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.jms.MessageProducer;
import javax.jms.Queue;
import javax.jms.Session;
import javax.jms.TextMessage;
import javax.jms.QueueSender;
import javax.jms.DeliveryMode;
import javax.jms.QueueSession;
import javax.jms.QueueConnection;
import javax.jms.QueueConnectionFactory;
import javax.jms.JMSException;

import com.ibm.mq.jms.MQConnectionFactory;

public class JmsTest {


	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		 Context context = null;
		 MQConnectionFactory factory = null;
		 Connection connection = null;
		 String factoryName = "TESTQM";
		 String destName = "INPUT";
		 Destination dest = null;
		 Session session = null;
		 MessageProducer producer = null; 
		
		 
		 //MessageConsumer receiver = null;
		
		// TODO Auto-generated method stub

		// get the initial context
		try { 
		 
			 // Create a Properties object and set properties appropriately
            Properties props = new Properties();
            props.put(Context.INITIAL_CONTEXT_FACTORY,
                "com.sun.jndi.fscontext.RefFSContextFactory");
            props.put(Context.PROVIDER_URL, "file:/D:/JMS/bindings/jms");

        	// create the JNDI initial context.
            context = new InitialContext(props);
            
           // look up the ConnectionFactory
           factory = (MQConnectionFactory) context.lookup(factoryName);
			
           // look up the Destination
           dest = (Destination) context.lookup(destName);

           // create the connection
           connection = factory.createConnection();         
         
           // create the session
           session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
           
           // create a producer
           producer = session.createProducer(dest);        
           producer.setDeliveryMode(DeliveryMode.NON_PERSISTENT);
           
           TextMessage message = session.createTextMessage();
           message.setText("Hello");     // msg_text is a String
                                                                              
	       // send the message
           producer.send(message); 
	                                                                          
	       // print what we did
	       System.out.println("sent: " + message.getText());

		
        } catch (JMSException exception) {
            exception.printStackTrace();
        } catch (NamingException exception) {
            exception.printStackTrace();
        } finally {
            // close the context
            if (context != null) {
                try {
                    context.close();
                } catch (NamingException exception) {
                    exception.printStackTrace();
                }
            }

            // close the connection
            if (connection != null) {
                try {
                    connection.close();
                } catch (JMSException exception) {
                	exception.printStackTrace();
                }
            }
        }
	}

}
