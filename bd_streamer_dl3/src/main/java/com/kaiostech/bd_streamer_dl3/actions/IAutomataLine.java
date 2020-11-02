package com.kaiostech.bd_streamer_dl3.actions;

/**
   This class represents an abstraction of a line inside an Automata.

   This interface is just used to initialize the Automata.

   It is used in order to make the initialization process of the Automata
   more formal and easier.
   
*/
public interface IAutomataLine {
    public IAction[] getAutomataLine();
}
