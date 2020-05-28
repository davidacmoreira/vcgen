package src;
 
import src.g.gAdaptor;
import src.g.types.*;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.ANTLRFileStream;
import org.antlr.runtime.tree.Tree;
import tom.library.utils.Viewer;
import tom.library.sl.*;
import java.util.*;
import java.lang.*;
import java.io.*;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.FileWriter;
import java.io.PrintWriter;

public class Main {
	%include{sl.tom}
	%include{util/HashMap.tom}
	%include{util/ArrayList.tom}
	%include{util/types/Collection.tom}
	%include{../gen/src/g/g.tom}

	private static List<String> vcs = new ArrayList<String>();
    private static List<String> smt = new ArrayList<String>();

    private static HashMap<String, String> variaveis = new HashMap<String, String>();
    private static HashMap<String, String> variaveis_smt = new HashMap<String, String>();
    private static List<String> variaveis_na = new ArrayList<String>();

	private static String pre;
    private static String postn;
    private static String poste;
    private static String inv;
    private static String ant;

    private static String preSmt;
    private static String postnSmt;
    private static String posteSmt;
    private static String invSmt;
    private static String antSmt;
    
    private static String ifAux;
    private static String ifAuxSmt;

    private static String assert_init = "(assert (not (=> ";
    private static int fl = 0;


	public static void main(String[] args) throws IOException {
		try{
			gLexer lexer = new gLexer(new ANTLRFileStream("../input_files/"+args[0]));
			System.out.println("\nFicheiro carregado: " + args[0]);
			CommonTokenStream tokens = new CommonTokenStream(lexer);
			gParser parser = new gParser(tokens);
			Tree t = (Tree) parser.prog().getTree();
			Instrucao term = (Instrucao) gAdaptor.getTerm(t);

			`TopDown(Strategy_Anotacoes()).visit(term);
			`TopDown(Strategy_VC()).visit(term);

			FileWriter dot_file = new FileWriter("../output_files/ast_"+args[0]+".dot");
			Viewer.toDot(term, dot_file);

			String command_dot = "dot -Tpng ../output_files/ast_" + args[0] + ".dot -o ../output_files/ast_" + args[0] + ".png";         
    		try{
    			Process process = Runtime.getRuntime().exec(command_dot);
    		}
    		catch (IOException e) {}

			System.out.println("\nArvore de sintaxe (AST) gerada em formato txt o ficheiro: ast_" + args[0] + ".txt");
			System.out.println("\nArvore de sintaxe (AST) gerada em formato dot o ficheiro: ast_" + args[0] + ".dot");
			System.out.println("\nArvore de sintaxe (AST) gerada em formato png o ficheiro: ast_" + args[0] + ".png");

			try {
				PrintWriter writer_ast = new PrintWriter("../output_files/ast_" + args[0] + ".txt", "UTF-8");
				PrintWriter writer_vcs = new PrintWriter("../output_files/vcs_" + args[0] + ".txt", "UTF-8");
				PrintWriter writer_smt = new PrintWriter("../output_files/" + args[0] + ".smt2", "UTF-8");
				
				writer_ast.println(term);

				for(String v : vcs)
					writer_vcs.println(v);
				
				System.out.println("\nCondicoes de verificacao geradas para o ficheiro: vcs_" + args[0] + ".txt");

				for(String s : smt)
					writer_smt.println(s);

				System.out.println("\nCondicoes de verificacao traduzidas para SMT-LIB no ficheiro: " + args[0] + ".smt2");

				writer_ast.close();
				writer_vcs.close();
				writer_smt.close();

				String command_z3 = "z3 -smt2 ../output_files/" + args[0] + ".smt2";         
	    		try{
	    			Process process = Runtime.getRuntime().exec(command_z3);
	    			System.out.println("\nVerificacao das condicoes de verificacao executada: ");
	    			BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));                                          
				    String r;
				    while ((r = reader.readLine()) != null)                           
				      	System.out.println(r + "\n");   
	    		}
	    		catch (IOException e) {}
			}
	 		catch (UnsupportedEncodingException e) {
			  	throw new AssertionError("UTF-8 NOT SUPPORTED");
			}
			catch (FileNotFoundException ex) {
	    		System.out.println("ERROR");
	    	}

		} catch(Exception e) {
			e.printStackTrace();
		}
	}

    %strategy Strategy_Anotacoes() extends Identity() {
     	visit Instrucao {
			Pre(anot) -> {
				ant = pre = anot_string(`anot);
				antSmt = preSmt = smt_string(`anot);
				`TopDown(Strategy_ID(0)).visit(`anot);
			}
			Postn(anot) -> {
				postn = anot_string(`anot);
				postnSmt = smt_string(`anot);
				`TopDown(Strategy_ID(1)).visit(`anot);
			}
			Poste(anot) -> {
				//
			}
      	}
    }

    %strategy Strategy_ID(int id_inst) extends Identity() {
		visit Expressao {
			Id(id) -> {
				if(id_inst == 0 && !(variaveis.containsKey(`id))){
					variaveis.put(`id+"", `id+"");
					variaveis_smt.put(`id+"", `id+"");
					smt.add("(declare-fun "+ `id +" () Int)");
				}
				if(!(variaveis.containsKey(`id)) && !(variaveis_na.contains(`id)))
					variaveis_na.add(`id+"");
			}
		}
    }

    %strategy Strategy_VC() extends Identity() {
		visit Instrucao {
			Cod(instr)->{
				rec_inst(`instr, 0);
			}
			Postn(anot) -> {
				for(String v : variaveis.keySet()){
					postn = postn.replace(v, variaveis.get(v));
			 		postnSmt = postnSmt.replace(v, variaveis_smt.get(v));

			 		if(fl >= 1){
				 		ifAux = postn.replace(v, ifAux);
				 		ifAuxSmt = postnSmt.replace(v, ifAuxSmt)+")))";

						vcs.set(vcs.size()-1, vcs.get(vcs.size()-1).concat(ifAux));
						smt.set(smt.size()-1, smt.get(smt.size()-1).concat(ifAuxSmt));

						if(fl == 2){
							vcs.set(vcs.size()-2, vcs.get(vcs.size()-2).concat(ifAux));
							smt.set(smt.size()-2, smt.get(smt.size()-2).concat(ifAuxSmt));
						}
					}
				}
				
 				if(fl <= 1){
	 				vcs.add(ant+" => "+postn);

					smt.add(assert_init + antSmt + postnSmt + ")))");
				}
				smt.add("(check-sat)");
			}
			Poste(anot) -> {
				//
			}
		}
     }

    private static String rec_inst(Instrucao instrucao, int flag) {
		%match(instrucao) {
			SeqInstrucao(inst_seq, inst*) -> {
					%match(inst_seq) {
						Atribuicao(id,exp1) -> {
			    			if(variaveis.containsKey(`id)){
			    				if(flag == 0){
			    					variaveis_smt.put(`id, smt_expr(`exp1));
			    					variaveis.put(`id, anot_expr(`exp1));
			    				}
			    				if(flag == 1){
			    					inv = inv.replace(variaveis.get(`id), anot_expr(`exp1));
			    					invSmt = invSmt.replace(variaveis.get(`id), smt_expr(`exp1));
			    				}
			    				if(flag == 2){ 
			    					fl++;
			    					ifAux = anot_expr(`exp1);
			    					ifAuxSmt = smt_expr(`exp1);
			    				}
			 				} 
			 				else if(variaveis_na.contains(`id)){
			 					if(flag == 0){
			 						postn = postn.replace(variaveis_na.get(variaveis_na.indexOf(`id)), anot_expr(`exp1));
			 						postnSmt = postnSmt.replace(variaveis_na.get(variaveis_na.indexOf(`id)), smt_expr(`exp1));
			    				}
			 					if(flag == 1){
			    					inv = inv.replace(variaveis_na.get(variaveis_na.indexOf(`id)), anot_expr(`exp1));
			    					invSmt = invSmt.replace(variaveis_na.get(variaveis_na.indexOf(`id)), smt_expr(`exp1));
			    				}
			    				if(flag == 2){
			    					postn = postn.replace(variaveis_na.get(variaveis_na.indexOf(`id)), anot_expr(`exp1));
			 						postnSmt = postnSmt.replace(variaveis_na.get(variaveis_na.indexOf(`id)), smt_expr(`exp1));
			    				}
			 				}
			 				else{
			 					fl++;
			 					ifAux = postn;
			    				ifAuxSmt = postnSmt;
			 				}
			 				smt.add("(check-sat)");
    					}

    					While(exp2, insta) -> {
    						ex_inv(`insta);
    						vcs.add(ant+" => "+inv);
    						smt.add(assert_init+antSmt+invSmt+")))");
    						ant = inv;
    						antSmt = invSmt;
    						rec_inst(`insta, 1);
    						vcs.add(ant+ " and " + anot_expr(`exp2) + " => " + inv);
    						smt.add(assert_init + antSmt + smt_expr(`exp2) + invSmt +")))");
    						ant = ant + " and " + "not("+anot_expr(`exp2) + ")";
    						antSmt = antSmt + "(not" + smt_expr(`exp2) + ")";
    						smt.add("(check-sat)");
    					}
    					
    					If(cond,instr1,instr2)->{
 							vcs.add(ant+" and "+anot_expr(`cond) + " => ");
    						smt.add(assert_init+antSmt+smt_expr(`cond));

    						if(ex_else(`instr2)){
    							rec_inst(`instr2, 2);
    							vcs.add(ant+" and "+ "not("+anot_expr(`cond)+")" + " => ");
    							smt.add(assert_init+antSmt+"(not"+smt_expr(`cond)+")");
    						}

    						ant =  ant + " and " + "not("+anot_expr(`cond) + ")";
    						antSmt = antSmt + "(not" + smt_expr(`cond) + ")";
    						rec_inst(`instr1, 2);  					
    					}
					}
				return rec_inst(`inst*, flag);
			}
		}
		return "";
	}

    private static boolean ex_else(Instrucao instrucao) {
		%match(instrucao) {
			SeqInstrucao(inst_seq, inst*) -> { return true; }
		}
		return false;
	}

	private static String ex_inv(Instrucao instrucao) {
		%match(instrucao) {
			SeqInstrucao(inst_seq, inst*) -> {
				%match(inst_seq){
					Inv(anot)-> {
						inv = anot_string(`anot);
						invSmt = smt_string(`anot);
					}
				}
			}
		}
		return "";
	}

	private static String atr_smt(Instrucao instrucao) {
		%match(instrucao) {
			Atribuicao(id,exp) -> { return "(= " + `id + " " + smt_expr(`exp) + " )"; }
		}
		return "";
	}

    private static String anot_string(Anotacoes anotacao) {
		%match(anotacao) {
			ListaAnot(arg1,tailArg*) -> { return anot_string(`arg1)+anot_string(`tailArg*); }
			Atr(instr) -> { return atr_string(`instr); }
			Cond(exp) -> { return anot_expr(`exp); }
		}
		return "";
	}

	private static String atr_string(Instrucao instrucao) {
		%match(instrucao) {
			Atribuicao(id,exp) -> { return `id+"="+anot_expr(`exp); }
		}
		return "";
	}

	private static String smt_string(Anotacoes anotacao) {
		%match(anotacao) {
			ListaAnot(arg1,tailArg*) -> { return smt_string(`arg1)+smt_string(`tailArg*); }
			Atr(instr) -> { return atr_smt(`instr); }
			Cond(exp) -> { return smt_expr(`exp); }
		}
		return "";
	}	

    private static String anot_expr(Expressao expressao) {
		%match(expressao) {
			ExpNum(exp1,op,exp2) -> {
				String exp_left = `anot_expr(exp1);
				String exp_rigth = `anot_expr(exp2);

				%match(op) {
					Mais() -> { return exp_left + "+" + exp_rigth; }
					Vezes() -> { return exp_left + "*" + exp_rigth; }
					Divide() -> { return exp_left + "/" + exp_rigth; }
					Menos() -> { return exp_left + "-" + exp_rigth; }
					Mod() -> { return exp_left.concat(exp_rigth); }
				}
				return "";
			}

			Id(id) -> {
				return `id; 
			}

			Pos(exp) -> { return `anot_expr(exp); }

			Neg(exp) -> { return "-"+`anot_expr(exp); }

			Nao(exp) -> { 
				String genExp = `anot_expr(exp);
				return genExp + "not";
			}

			Condicional(condicao,exp1,exp2) -> {
				String genCondicao = `anot_expr(condicao);
				String exp_left = `anot_expr(exp1);
				String exp_rigth = `anot_expr(exp2);

				return genCondicao.concat(exp_left).concat(exp_rigth);
			}

			Int(i) -> { return ""+`i; }

			Ou(cond1,cond2) -> {
				String genCond1 = `anot_expr(cond1);
				String genCond2 = `anot_expr(cond2);

				return genCond1 + " or " + genCond2 ;
			}

			E(cond1,cond2) -> {
				String genCond1 = `anot_expr(cond1);
				String genCond2 = `anot_expr(cond2);
				
				return genCond1 + " and " + genCond2;
			}

			Comp(exp1,opComp,exp2) -> {
				String exp_left = `anot_expr(exp1);
				String exp_rigth = `anot_expr(exp2);

				%match(opComp) {
					Maior() -> { return exp_left + ">" + exp_rigth; }
					Menor() -> { return exp_left + "<" + exp_rigth; }
					MaiorQ() -> { return exp_left + ">=" + exp_rigth; }
					MenorQ() -> { return exp_left + "<=" + exp_rigth; }
					Dif() -> { return exp_left + "!=" + exp_rigth; }
					Igual() -> { return exp_left + "==" + exp_rigth; }
				}
			}

			Expressoes(exp1, exp*) -> {
				String genExp = `anot_expr(exp1);
				String exps = genExp.concat(`anot_expr(exp*));

				return exps;
			}
		}
		return "";
	}

    private static String smt_expr(Expressao expressao) {
		%match(expressao) {
			ExpNum(exp1,op,exp2) -> {
				String exp_left = `smt_expr(exp1);
				String exp_rigth = `smt_expr(exp2);

				%match(op) {
					Mais() -> { 
						return  "(+ " + exp_left +" "+ exp_rigth + ")"; }
					Vezes() -> { 
						return "(* " + exp_left +" "+ exp_rigth + ")"; }
					Divide() -> { 
						return "(/ " +  exp_left +" "+ exp_rigth + ")"; }
					Menos() -> { 
						return "(- " + exp_left +" "+ exp_rigth + ")"; }
					Mod() -> {
						return exp_left.concat(exp_rigth); }
				}
				return "";
			}

			Id(id) -> {
				return `id; 
			}

			Pos(exp) -> { return `smt_expr(exp); }

			Neg(exp) -> { return "-"+`smt_expr(exp); }

			Nao(exp) -> { 
				String genExp = `smt_expr(exp);
				return "(not " + genExp + ")";
			}

			Condicional(condicao,exp1,exp2) -> {
				String genCondicao = `smt_expr(condicao);
				String exp_left = `smt_expr(exp1);
				String exp_rigth = `smt_expr(exp2);

				return genCondicao.concat(exp_left).concat(exp_rigth);
			}

			Int(i) -> { return "" + `i; }

			Ou(cond1,cond2) -> {
				String genCond1 = `smt_expr(cond1);
				String genCond2 = `smt_expr(cond2);

				return "(or " + genCond1 + genCond2 + ")";
			}

			E(cond1,cond2) -> {
				String genCond1 = `smt_expr(cond1);
				String genCond2 = `smt_expr(cond2);
				
				return "(and " + genCond1 + genCond2 + ")";
			}

			Comp(exp1,opComp,exp2) -> {
				String exp_left = `smt_expr(exp1);
				String exp_rigth = `smt_expr(exp2);

				%match(opComp) {
					Maior() -> { return "(> " + exp_left +" "+ exp_rigth + ")"; }
					Menor() -> { return "(< " + exp_left +" "+ exp_rigth + ")"; }
					MaiorQ() -> { return "(>= " + exp_left +" "+ exp_rigth + ")"; }
					MenorQ() -> { return "(<= " + exp_left +" "+ exp_rigth + ")"; }
					Dif() -> { return "(not(= " + exp_left +" "+ exp_rigth + ")))"; }
					Igual() -> { return "(= " + exp_left +" "+ exp_rigth + ")"; }
				}
			}

			Expressoes(exp1, exp*) -> {
				String genExp = `smt_expr(exp1);
				String exps = genExp.concat(`smt_expr(exp*));

				return exps;
			}
		}
		return "";
	}
}
