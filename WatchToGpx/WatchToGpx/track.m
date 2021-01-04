//
//  track.m
//  WatchToGpx
//
//  Created by Philippe DESROZIERS on 01/01/2021.
//  Copyright © 2021 Philippe DESROZIERS. All rights reserved.
//

#import "track.h"

@class TrameArrayControler;

NSString * _Nonnull bufsegment;
NSMutableString * _Nonnull bufsegmentGPX;
NSString * _Nonnull bufentete;
BOOL Apple;

int nbreTrames;

@implementation track


- (IBAction)Lance:(id)sender {
    
    Apple = NO;
    
    int i; // Loop counter.
    
    // Ouverture du fichier trace et placement dans le buffer buftrace -----------------------------
    
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg runModal] == NSOKButton;
    
    NSArray* files = [openDlg filenames];
    NSString* fileName = [files objectAtIndex:0];
    NSString * buftrace;
    buftrace =[[NSString alloc] initWithContentsOfFile:fileName];
    
    [nameTrack setStringValue:fileName];
    
    // Calcul du buffer entete --------------------------------------------
    
    NSRange enteteRange;
    enteteRange = [buftrace rangeOfString:@"<?xml"];
    NSUInteger debutEntete = enteteRange.location-5;
    NSLog(@"\n debutEntete = %lu ", debutEntete);
    
    NSRange enteteRangefin;
    enteteRangefin = [buftrace rangeOfString:@"<trkseg>"];
    NSUInteger finEntete = enteteRangefin.location+8;
    NSLog(@"\n finEntete = %lu ", finEntete);
    
    NSUInteger lenEntete = (finEntete - debutEntete); // calcul de la longueur de bufsegment
    NSLog(@"\n lenEntete = %lu ", lenEntete);
    
    bufentete = [buftrace substringWithRange:NSMakeRange(debutEntete+5, lenEntete-5)];   // (5 = longueur du tag "<?xml")
    
    [affentete insertText:bufentete];  // affiche texte de buftrkseg dans un nsscrollview
    
    
    // Calcul du creator de la trace --------------------------------------------
    
    int hybrid = 0;
    NSRange creator;
    creator = [bufentete rangeOfString:@"Apple"];  //Apple -> test si trace issue de GPS Apple iWatch
    hybrid = creator.location;
    NSLog(@"\n hybrid est %d --------- ", (int)hybrid);
    if(hybrid > -1) Apple = YES;
    
    if(Apple == NO){
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        //[alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Cette trace n'est pas issue d'un GPS iWatch!"];
        [alert setInformativeText:@"Le programme ne peut continuer sans trace GPS iWatch et doit arrêter fonctionnement."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        exit(0);
    }
    
    
    
    // Calcul du buffer bufsegment --------------------------------------------
    
    NSRange trksegRange;
    trksegRange = [buftrace rangeOfString:@"<trkseg>"];
    NSUInteger debutTrkseg = trksegRange.location;
    NSLog(@"\n debutTrkseg = %lu ", debutTrkseg);
    
    NSRange trksegRangefin;
    trksegRangefin = [buftrace rangeOfString:@"</trkseg>"];
    NSUInteger finTrkseg = trksegRangefin.location;
    NSLog(@"\n finTrkseg = %lu ", finTrkseg);
    
    NSUInteger lenTrkseg = (finTrkseg - debutTrkseg); // calcul de la longueur de bufsegment
    NSLog(@"\n lenTrkseg = %lu ", lenTrkseg);
    
    bufsegment = [buftrace substringWithRange:NSMakeRange(debutTrkseg+8, lenTrkseg-8)];   // (8 = longueur du tag "<trkseg>")
    
    [afftrak insertText:bufsegment];  // affiche texte de buftrkseg dans un nsscrollview
    
    
    
    // Calcul du nombre de trames dans bufsegment -----------------------------

    NSArray *bufTrames = [bufsegment componentsSeparatedByString:@"</trkpt>"];
    
    nbreTrames = [bufTrames count];
    nbreTrames --;
    NSLog(@"\n Nombre de trames de bufsegmentItems : %d",nbreTrames);
    [NbreTrame setIntValue:nbreTrames];
    
    
    // Conversion des trames iWatch en Gpx -----------------------------    
    
    NSString * latit;
    NSString * longit;
    NSString * elevatime;
    
    NSRange premrangelat;
    NSRange derangelat;
    int premlat;
    int derlat;
    int difflat;
    
    NSRange premrangelon;
    NSRange derangelon;
    int premlon;
    int derlon;
    int difflon;
    
    NSRange premrangelevtime;
    NSRange derangelevtime;
    int premlevtime;
    int derlevtime;
    int difflevtime;
    
    bufsegmentGPX = [[NSMutableString alloc] initWithString:bufentete];
    
    
    if(nbreTrames > 0){
        
        for( int i = 0;i < nbreTrames;i++){
        //for( int i = 0;i < 2;i++){
            
            //Placement de la latitude
            premrangelat = [bufTrames[i] rangeOfString:@"lat="];
            derangelat = [bufTrames[i] rangeOfString:@"<ele>" options:NSBackwardsSearch];
            premlat = premrangelat.location;
            derlat = derangelat.location -1;
            difflat = derlat - premlat;
            latit = [bufTrames[i] substringWithRange:NSMakeRange(premlat, difflat)];
            //NSLog(@"\n bufTrames[%i] = %@ ", i,bufTrames[i]);
            //NSLog(@"\n premlat = %i ---- derlat %i --------- ", premlat,derlat);
            //NSLog(@"\n latit = %@ ", latit);
            
            //Placement de la longiitude
            premrangelon = [bufTrames[i] rangeOfString:@"lon="];
            derangelon = [bufTrames[i] rangeOfString:@"lat" options:NSBackwardsSearch];
            premlon = premrangelon.location;
            derlon = derangelon.location;
            difflon = (derlon - premlon)-1;
            longit = [bufTrames[i] substringWithRange:NSMakeRange(premlon, difflon)];
            //NSLog(@"\n bufTrames[%i] = %@ ", i,bufTrames[i]);
            //NSLog(@"\n premlon = %i ---- derlon %i --------- ", premlon,derlon);
            //NSLog(@"\n longit = %@ ", longit);
            
            //Placement de l'élévation + time
            premrangelevtime = [bufTrames[i] rangeOfString:@"<ele>"];
            derangelevtime = [bufTrames[i] rangeOfString:@"</time>" options:NSBackwardsSearch];
            premlevtime = premrangelevtime.location;
            derlevtime = derangelevtime.location;
            difflevtime = derlevtime - premlevtime;
            elevatime = [bufTrames[i] substringWithRange:NSMakeRange(premlevtime, difflevtime)];
            //NSLog(@"\n bufTrames[%i] = %@ ", i,bufTrames[i]);
            //NSLog(@"\n premlevtime = %i ---- derlevtime %i --------- ", premlevtime,derlevtime);
            //NSLog(@"\n elevatime = %@ ", elevatime);
            
            
            [bufsegmentGPX appendString:@"<trkpt "];
            [bufsegmentGPX appendString:latit];
            [bufsegmentGPX appendString:@" "];
            [bufsegmentGPX appendString:longit];
            [bufsegmentGPX appendString:@">"];
            [bufsegmentGPX appendString:elevatime];
            [bufsegmentGPX appendString:@"</time></trkpt>\n"];
            
        }
        /*
        [bufsegmentGPX appendString:@"<trkpt "];
        [bufsegmentGPX appendString:latit];
        [bufsegmentGPX appendString:@" "];
        [bufsegmentGPX appendString:longit];
        [bufsegmentGPX appendString:@">"];
        [bufsegmentGPX appendString:elevatime];
        [bufsegmentGPX appendString:@"</time></trkpt>"];
         */
        
        
        [bufsegmentGPX appendString:@"</trkseg>\n</trk>\n</gpx>"];
        
        NSLog(@"\n\n\n bufsegmentGPX = %@ ", bufsegmentGPX);
        
        [affgpx insertText:bufsegmentGPX];  // affiche texte de buftrkseg dans un nsscrollview
        
        //------------------------------------------
        
        
        NSString *newname;
        
        //déterminer le nouveau path et nom du fichier à sauvegarder
        newname = [fileName lastPathComponent];
        newname = [@"Garmin-" stringByAppendingString:newname];
        NSLog(@"newname = %@",newname);
       
        NSString *dataPath = [fileName stringByDeletingLastPathComponent];
        
        dataPath = [dataPath stringByAppendingPathComponent:@"/Garmin_GPX/"];
        NSLog(@"dataPath = %@", dataPath);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:NULL]; //Create folder
        }
        dataPath = [dataPath stringByAppendingPathComponent:newname];
        NSLog(@"dataPath = %@", dataPath);
        
        [bufsegmentGPX writeToFile:dataPath atomically:YES encoding:NSUTF8StringEncoding error:nil];

    
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        //[alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"La trace a bien été convertie et sauvegardée à cette adresse : "];
        
        [alert setInformativeText:dataPath];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
        //exit(0);
    
    
    }
    
}


@end
