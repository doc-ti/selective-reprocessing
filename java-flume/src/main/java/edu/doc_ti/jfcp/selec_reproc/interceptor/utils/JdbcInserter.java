package edu.doc_ti.jfcp.selec_reproc.interceptor.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class JdbcInserter {
	
	private static final Logger LOG = LoggerFactory.getLogger(JdbcInserter.class);
	Connection conn;
	private PreparedStatement pstmt;
	
	
	public JdbcInserter (String jdbcUrl) {
		
		try { Class.forName("com.mysql.jdbc.Driver"); } catch (ClassNotFoundException e)
		{ LOG.error("Could not find the JDBC driver class."); e.printStackTrace();  }

		try {
			LOG.info("Connecting to "+ jdbcUrl);
	        conn = DriverManager.getConnection( jdbcUrl);
	        conn.setAutoCommit(true) ;

	        Statement stmt = conn.createStatement();
			try {
				stmt.execute ("create table info_files ( filename varchar(200), status varchar(20), records int, ts_insert timestamp, ts_check timestamp  DEFAULT '2000-01-01 00:00:00', records_es int ) ") ;
			} catch (SQLException e) {
				LOG.error("FELIPE" );
				LOG.error(e.getMessage() );
			}

			LOG.info("CREATED TABLE") ;
			
	        stmt.close() ;
	        
	        pstmt = conn.prepareStatement("insert into info_files (filename, status, records, ts_insert, ts_check) values (?, 'PENDING', ?, sysdate() , null ) ")  ;

		} catch (SQLException e) {
			LOG.error(e.getMessage()) ;
			e.printStackTrace(); 
		}

	}
	
	
	public void insert(FileRegister fr) {
		
		if ( fr.getPosition() == 0 || fr.getFile() == null || fr.getFile().length() == 0 ) {
			return ;
		}
		
		try {
			LOG.info(String.format( "Inserting data for (%s) : (%d)", fr.getFile(), fr.getPosition()))  ;
			pstmt.setString(1, fr.getFile());
			pstmt.setInt(2, fr.getPosition());
			pstmt.execute();
		} catch (SQLException e) {
			LOG.error(e.getMessage()) ;
		}
	}
	public void close() {
        try {
			conn.close() ;
		} catch (SQLException e) {
			LOG.error(e.getMessage()) ;
			e.printStackTrace();
		}
	}
}
