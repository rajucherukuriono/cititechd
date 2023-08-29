public class ReplaceSpecialChar{
    List<String> specialList = new List<String>();
    String special = 'Barclays:       Barclays';
    
    public ReplaceSpecialChar(){
        String name = '{B]@i%s*w:?,-a$j#e)e(t! S^a.m}a]l[';
        name = name.replaceAll('[^a-zA-Z0-9\\s+]', '');
        System.debug('Name-' + name);

    }
}