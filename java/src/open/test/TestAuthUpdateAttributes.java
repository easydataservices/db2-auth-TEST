package com.easydataservices.open.test;

import java.util.List;
import java.util.Arrays;
import java.util.concurrent.ThreadLocalRandom;
import java.util.logging.Logger;
import com.easydataservices.open.auth.AuthAttributesDao;
import com.easydataservices.open.auth.AuthSessionDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.auth.StoreAttribute;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for updating attributes.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthUpdateAttributes extends TestAuthPayload {
  private static final String className = TestAuthUpdateAttributes.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private AuthSessionDao authSessionDao;
  private AuthAttributesDao authAttributesDao;
  private String sessionIdPrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s", this, bootstrap));
    authSessionDao = new AuthSessionDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authAttributesDao = new AuthAttributesDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadPrefix1() + "_";
    logger.finer(() -> String.format("RETURN %s", this));
  }

  public void payload(int rangeValue, int iteration) throws Exception {
    StoreAttribute attribute;
    String attributeName;
    List<StoreAttribute> attributeList = null;

    logger.finer(() -> String.format("ENTRY %s %s %s", this, rangeValue, iteration));
    String sessionId = sessionIdPrefix + rangeValue;
    StoreSession session = authSessionDao.getSession(sessionId);
    if (session != null) {
      String actionText = "Upserted";
      try {
        attributeList = authAttributesDao.getAttributes(sessionId, 0);
      }
      catch (NullPointerException exception) {
        System.out.println("** NULL");
        System.exit(8);
      }
      int attributeIndex = ThreadLocalRandom.current().nextInt(1, 9);
      attributeName = "ATTRIBUTE_" + (attributeIndex + 1);
      attribute = new StoreAttribute(attributeName);
      int i = ThreadLocalRandom.current().nextInt(0, 8);
      if (i < 7) {
        int size = ((int) Math.pow(2, i)) * 32000;
        char[] charArray = new char[size];
        Arrays.fill(charArray, '?');
        attribute.setObject("large object:" + new String(charArray) + attributeName);  
      }
      else {
        actionText = "Deleted";
        attribute.setObject(null);
      }
      attributeList.add(attribute);
      authAttributesDao.saveAttributes(sessionId, attributeList);
      logger.info(actionText + " session " + sessionId + " attribute " + attributeName + ".");
    }
    else {
      logger.info("Session " + sessionId + " does not exist.");
    }
    logger.finer(() -> String.format("RETURN %s", this));
  }
}
