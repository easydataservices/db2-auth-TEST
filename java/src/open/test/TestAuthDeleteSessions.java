package com.easydataservices.open.test;

import java.util.logging.Logger;
import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for deletng sessions.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthDeleteSessions extends TestAuthPayload {
  private static final String className = TestAuthDeleteSessions.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private AuthControlDao authControlDao;
  private String sessionIdPrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s", this, bootstrap));
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadPrefix1() + "_";
    logger.finer(() -> String.format("RETURN %s", this));
  }

  public void payload(int rangeValue, int iteration) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s %s", this, rangeValue, iteration));
    String sessionId = sessionIdPrefix + rangeValue;
    authControlDao.removeSession(sessionId);
    logger.info("Deleted session " + sessionId + ".'");
    logger.finer(() -> String.format("RETURN %s", this));
  }
}
