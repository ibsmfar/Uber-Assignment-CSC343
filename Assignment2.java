import java.sql.*;
// You should use this class so that you can represent SQL points as
// Java PGpoint objects.
import org.postgresql.geometric.PGpoint;
import java.util.Date;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to uber, public.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
      // Implement this method!
      PreparedStatement p = null;
      //boolean isConnectedAndSet = false;
      
      try{
         connection = DriverManager.getConnection(URL, username, password);

         String s = "SET SEARCH_PATH TO uber, public";
         p = connection.prepareStatement(s);
         p.execute();       

      }catch(Exception e){
         return false;
      }
      return true;
   }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
      // Implement this method!
      try{
         connection.close();
         
      } catch(SQLException s){
         return false;
      }
      return true;
   }
   
   /* ======================= Driver-related methods ======================= */

   /**
    * Records the fact that a driver has declared that he or she is available 
    * to pick up a client.  
    *
    * Does so by inserting a row into the Available table.
    * 
    * @param  driverID  id of the driver
    * @param  when      the date and time when the driver became available
    * @param  location  the coordinates of the driver at the time when 
    *                   the driver became available
    * @return           true if the insertion was successful, false otherwise. 
    */
   public boolean available(int driverID, Timestamp when, PGpoint location) {
      // Implement this method!

      PreparedStatement p = null;
      try{
         String s =  "INSERT INTO available " + 
                     "VALUES (?,?,?)"; 
         p = connection.prepareStatement(s);

         p.setInt(1, driverID);
         p.setTimestamp(2, when);
         p.setObject(3, location);

         p.executeUpdate();
      } catch (SQLException s){
	 System.out.println(s);
         return false;
      }
      return true;
   }

   /**
    * Records the fact that a driver has picked up a client.
    *
    * If the driver was dispatched to pick up the client and the corresponding
    * pick-up has not been recorded, records it by adding a row to the
    * Pickup table, and returns true.  Otherwise, returns false.
    * 
    * @param  driverID  id of the driver
    * @param  clientID  id of the client
    * @param  when      the date and time when the pick-up occurred
    * @return           true if the operation was successful, false otherwise
    */
   public boolean picked_up(int driverID, int clientID, Timestamp when) {
      // Implement this method!
      ResultSet r = null;
      PreparedStatement p = null;
			

      try{
         String s1 = "SELECT dispatch.request_id as request_id " +
		     "FROM dispatch JOIN request ON dispatch.request_id = request.request_id " +
                     "WHERE request.client_id = ? and dispatch.driver_id = ? " +
                     "EXCEPT " +
		     "SELECT request_id from pickup";

         p = connection.prepareStatement(s1);
         p.setInt(1, clientID);
         p.setInt(2, driverID);

         r =  p.executeQuery();

         // moves the pointer to the first row, if this is row is empty
         // (meaning that this dispatch has been recorded in pickup), then
         // there is nothing to insert. Return false.
	 //System.out.println("First query is fine");
         if (!r.next())
            return false;
         //System.out.println("there is definitely a result");
         int request_id = r.getInt(1);

         String s2 = "INSERT INTO pickup " +
                     "VALUES (?,?)";

         p = connection.prepareStatement(s2);
         p.setInt(1, request_id);
         p.setTimestamp(2, when);

	 //System.out.println("About to execute fam");

         p.executeUpdate();

      } catch(SQLException s){
	 System.out.println(s);
         return false;

      }
      return true;
   }
   
   /* ===================== Dispatcher-related methods ===================== */

   /**
    * Dispatches drivers to the clients who've requested rides in the area
    * bounded by NW and SE.
    * 
    * For all clients who have requested rides in this area (i.e., whose 
    * request has a source location in this area), dispatches drivers to them
    * one at a time, from the client with the highest total billings down
    * to the client with the lowest total billings, or until there are no
    * more drivers available.
    *
    * Only drivers who (a) have declared that they are available and have 
    * not since then been dispatched, and (b) whose location is in the area
    * bounded by NW and SE, are dispatched.  If there are several to choose
    * from, the one closest to the client's source location is chosen.
    * In the case of ties, any one of the tied drivers may be dispatched.
    *
    * Area boundaries are inclusive.  For example, the point (4.0, 10.0) 
    * is considered within the area defined by 
    *         NW = (1.0, 10.0) and SE = (25.0, 2.0) 
    * even though it is right at the upper boundary of the area.
    *
    * Dispatching a driver is accomplished by adding a row to the
    * Dispatch table.  All dispatching that results from a call to this
    * method is recorded to have happened at the same time, which is
    * passed through parameter 'when'.
    * 
    * @param  NW    x, y coordinates in the northwest corner of this area.
    * @param  SE    x, y coordinates in the southeast corner of this area.
    * @param  when  the date and time when the dispatching occurred
    */
   public void dispatch(PGpoint NW, PGpoint SE, Timestamp when) {
      // Implement this method!

      try{
	String clearCRView = "DROP VIEW IF EXISTS clientrequest CASCADE";
	PreparedStatement clearView1 = connection.prepareStatement(clearCRView);
	clearView1.execute();
	
	String clearCBView = "DROP VIEW IF EXISTS clientbillings CASCADE";
	PreparedStatement clearView2 = connection.prepareStatement(clearCBView);
	clearView2.execute();
	
	String clearCBLView = "DROP VIEW IF EXISTS clientBillingsLocation CASCADE";
	PreparedStatement clearView3 = connection.prepareStatement(clearCBLView);
	clearView3.execute();
	
	String clearAVDView = "DROP VIEW IF EXISTS avDrivers CASCADE";
	PreparedStatement clearView4 = connection.prepareStatement(clearAVDView);
	clearView4.execute();

         String view1 = "CREATE VIEW clientrequest as " +
			"SELECT request_id, client_id, location " +
			"FROM request join place on source = name " +
			"WHERE request_id in " +
			"(SELECT request_id from request " +
			"EXCEPT " +
			"SELECT request_id from dispatch) AND " +
			Double.toString(NW.x) + " <= location[0] AND " +
			Double.toString(SE.x) + " >= location[0] AND " +
			Double.toString(NW.y) + " >= location[1] AND " +
			Double.toString(SE.y) + " <= location[1]";			

         PreparedStatement p1 = connection.prepareStatement(view1);
         p1.execute();


	String view2 =	"CREATE VIEW clientbillings as " +
			"(SELECT clientrequest.request_id as request_id, clientrequest.client_id as client_id, billings " + 
			"FROM clientrequest, (SELECT request.client_id as client_id, sum(amount) as billings " + 
			"FROM billed JOIN request ON billed.request_id = request.request_id " +
			"GROUP BY request.client_id) totals1 " +
			"WHERE clientrequest.client_id = totals1.client_id) " +
			"UNION " +
			"(SELECT request_id, client_id, 0 as billings " +
			"FROM clientrequest " +
			"WHERE client_id not in " +
			"(SELECT client_id FROM request JOIN billed ON billed.request_id = request.request_id)) " +
			"ORDER BY billings DESC";
		    
	PreparedStatement p2 = connection.prepareStatement(view2);
	p2.execute();

	String clientBillingsLocation = "CREATE VIEW clientBillingsLocation as " +
					"SELECT clientbillings.request_id as request_id, clientbillings.client_id as client_id, location, billings " +
					"FROM clientbillings, clientrequest " +
					"WHERE clientbillings.request_id = clientrequest.request_id " +
					"AND clientbillings.client_id = clientrequest.client_id " +
					"ORDER BY billings DESC";

	PreparedStatement p3 = connection.prepareStatement(clientBillingsLocation);
	p3.execute();

	//int tot_clients = 0;

	//while (CR.next()){
	//	tot_clients++;
	//}

	String avDrivers = "CREATE VIEW avDrivers as " +
			   "SELECT available.driver_id as driver_id, available.datetime as datetime, location " +
			   "FROM available, " +
			   "(SELECT driver_id, max(datetime) as datetime " +
			   "FROM available " + 
			   "WHERE driver_id in " +
			   "((SELECT DISTINCT available.driver_id as driver_id " + //DRIVERS WHO HAVE BEEN NOT BEEN DISPATCHED SINCE
			   "FROM available, " + 				//dispatch ON available.driver_id = dispatch.driver_id " +
			   	"(SELECT driver_id, max(datetime) as datetime " +
			   	"FROM dispatch " +
			   	"GROUP BY driver_id) maxes WHERE available.driver_id = maxes.driver_id AND "+
			   	"(available.datetime - maxes.datetime) > INTERVAL '0') " +
			   //"WHERE (available.datetime - dispatch.datetime) > INTERVAL '0') " + //the latest maximum dispatch time for each driver
			 //CHECKING THAT THEIR AVAIABLE TIME IS THE MOST RECENT TIME COMPARED TO DISPATCH TIMES 
			   "UNION " +
			   "(SELECT driver_id " +	//DRIVERS WHO HAVE NEVER BEEN DISPATCHED
			   "FROM available " +
			   "WHERE driver_id in " +
			   "(SELECT driver_id FROM available EXCEPT SELECT driver_id FROM dispatch))) AND " +
			   Double.toString(NW.x) + " <= location[0] AND " +
			   Double.toString(SE.x) + " >= location[0] AND " +
			   Double.toString(NW.y) + " >= location[1] AND " +
			   Double.toString(SE.y) + " <= location[1] " +
			   "GROUP BY driver_id) intermediate " +
			   "WHERE available.driver_id = intermediate.driver_id and " +
			   "available.datetime = intermediate.datetime";

	
	PreparedStatement p4 = connection.prepareStatement(avDrivers);
	p4.execute();
	//p4.setDouble(1, NW.x); //NW.X
	//p4.setDouble(2, SE.x); //SE.X
	//p4.setDouble(3, NW.y); //NW.y
	//p4.setDouble(4, SE.y); //SE.y

	
	//int tot_drivers = 0;
	//while (avD.next()){
	//	tot_drivers++;
	//}
	
	PreparedStatement p5 = connection.prepareStatement("SELECT * FROM clientBillingsLocation");
	ResultSet CR = p5.executeQuery();

	PreparedStatement p6 = connection.prepareStatement("SELECT * FROM avDrivers");
	ResultSet AVD = p6.executeQuery();
	
	int tot_clients = 0;

	while (CR.next()){
		tot_clients++;
	}
	
	int tot_drivers = 0;
	while (AVD.next()){
		tot_drivers++;
	}
	
	
	//String driversToClients = "SELECT
	
	
	int i;
	if (tot_clients <= tot_drivers) {
		i = tot_clients;
	} else {
		i = tot_drivers;
	}

	//System.out.println(tot_drivers + ", " + tot_clients + ", " + i);
	
	
	 
	
	for (int j = 0; j < i; j ++) {
		String result = "SELECT driver_id, clientBillingsLocation.request_id as request_id, avDrivers.location " +
		 		"FROM avDrivers, clientBillingsLocation " +
				"ORDER BY billings DESC, avDrivers.location <@> clientBillingsLocation.location";

		PreparedStatement f1 = connection.prepareStatement(result);
		
		ResultSet r = f1.executeQuery();
		
		r.next();
		
		int driver_id = r.getInt(1);
		int request_id = r.getInt(2);
		PGpoint p = (PGpoint) r.getObject(3);
		String insert = "INSERT INTO dispatch " + 
				"VALUES (?, ?, ?, ?)";
		PreparedStatement f2 =  connection.prepareStatement(insert);
		f2.setInt(1, request_id);
		f2.setInt(2, driver_id);
		f2.setObject(3, p);
		f2.setTimestamp(4, when); 
		f2.executeUpdate();
	}



      } catch(Exception e){
	 System.out.println(e);

      }
   }

   public static void main(String[] args) {
	try{
      // You can put testing code in here. It will not affect our autotester.
		Assignment2 j = new Assignment2();
		System.out.println("Trying to Connect");
		String url = "jdbc:postgresql://localhost:5432/csc343h-faroo127";
		j.connectDB(url, "faroo127", "");
		System.out.println("############ Successful in connecting to database ############");
	      	//System.out.println("Boo!");
		
		Date date = new Date();
		long time = date.getTime();
		
		Timestamp ts = new Timestamp(time);
		//PGpoint p = new PGpoint(1, 2.0);
		//System.out.println("Testing available method");
		
		//System.out.println(j.available(12345, ts, p));
		//System.out.println("Testing picked up method");
		//System.out.println(j.picked_up(12345, 99, ts));
		PGpoint nw = new PGpoint(-2.0, 55);
		PGpoint se = new PGpoint(90.0, 0);
		
		j.dispatch(nw, se, ts);
		

		

	}catch(Exception e){
		System.out.println(e);
	}
   }

}
