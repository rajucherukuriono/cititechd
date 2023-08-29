trigger HVTrigger on High_Volume__e (after insert) {
    //list<High_Volume__e> hvl = new <High_Volume__e>();
    
    for(High_Volume__e hv : trigger.new){
    //Database.saveResult sr = Eventbus.publish(hv);
    //if (sr.isSuccess())
        System.debug('--------------->>Successfully published');
    //else
    //    System.debug('--------------->>failed to publish');    
    
    }

}