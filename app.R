library(shiny)
library(shinydashboard)
library(readxl)
library(tidyr)
library(dplyr)
library(googleVis)
library(DT)
library(highcharter)
library(googlesheets)


# Loading data from Google sheet ------------------------------------------

key <- gs_key(x = "1Dc3hY5naKOAA-1epWzt41fZWWN5GyRhrVriO1vUAUl0")
data <- gs_read(key)
teacher_ed <- gs_read(ss = key,ws = "teacher_ed")


# Creating helper functions -----------------------------------------------


selector <- function(x){
  
  temp <- data %>% filter(Subcategory==x)
  temp <- spread(temp,Type, Value)
  
 temp <-   if(ncol(temp) ==5) {
      temp %>% select(Year, Category, Subcategory, College, Benchmark)
      } else {
        temp %>% select(Year, Category, Subcategory, College)
      }
   
  temp$Year <- as.character(temp$Year)
  temp}


latest_val <- function(data,  target, type=c("percent","ratio","value", "dollar"), subtitle){
  
  button <- function(target){paste0("<a href=# data-toggle='modal' data-target='#",target,"'",icon("search-plus","fa-lg"),"</a>")}
  
  tip <-  ifelse(type=="percent","%",ifelse(type=="ratio",":1",""))
  
  dollar <- function(data){
    denomination <- ifelse(data>1000000,"m", "k")
    data <- ifelse(data>1000000,data/1000000, data/1000)
    myNum <- sprintf("$%.f%s", data,denomination)
    prettyNum(myNum,big.mark=",")
    
  }
  
 
   val <- function(x){
    x$Year <- as.numeric(x$Year)
    num = x$College[x$Year == max(x$Year)]
    num_before = x$College[x$Year == max(x$Year-1)]
    
    list(num=ifelse(type=="dollar",dollar(num),prettyNum(num,big.mark=",")),
    #  num_before = if_else(num > num_before,"<i class='positive fa fa-arrow-up'></i>", "<i class='negative fa fa-arrow-down'></i>"),
         year = paste(x$Year[x$Year==max(x$Year)],1+as.numeric(substr(x$Year[x$Year == max(x$Year)],3,4)),sep="-")
    )    
  }
  
  paste0("<div id=box class=fade-in one> <p class=hvr-grow-shadow id=value>", 
         paste0(val(data)$num,tip), val(data)$num_before ,"</p><p id=period>", val(data)$year,"<br>",button(target),"</p></div><br><br><br><br><p id=subtitle >",subtitle,"</p>")
  
}


popup_val <- function(data,  type=c("percent","ratio","value","dollar"), subtitle){
  
  tip <-  ifelse(type=="percent","%",ifelse(type=="ratio",":1",""))
  
  
  dollar <- function(data){
    denomination <- ifelse(data>1000000,"m", "k")
    data <- ifelse(data>1000000,data/1000000, data/1000)
    myNum <- sprintf("$%.f%s", data,denomination)
    prettyNum(myNum,big.mark=",")
    
  }
  
  
  val <- function(x){
    x$Year <- as.numeric(x$Year)
    num = x$College[x$Year == max(x$Year)]
    num_before = x$College[x$Year == max(x$Year-1)]
    
    list(num=ifelse(type=="dollar",dollar(num),prettyNum(num,big.mark=",")),
 #     num_before = if_else(num > num_before,"<i class='positive fa fa-arrow-up'></i>", "<i class='negative fa fa-arrow-down'></i>"),
         year = paste(x$Year[x$Year==max(x$Year)],1+as.numeric(x$Year[x$Year==max(x$Year)]),sep="-")
    )    
  }
  
  paste0("<div id=box class=fade-in one> <p class=hvr-grow-shadow id=value>", 
 paste0(val(data)$num,tip), val(data)$num_before ,"</p><p id=popup_period>", val(data)$year,"</p></div><br><br><br><br><br><br><p id=popup_subtitle>",subtitle,"</p>")
  
}

additional <- function(minval, maxval){
  range <- paste(paste0("{minValue:",minval), paste0("maxValue:",maxval,"}"),sep = ",")
  list(vAxis=range, pointSize=5,legend="bottom",focusTarget = 'category',vAxes="[{format:'short'}]",
       chartArea="{left:35,top:10,width:\"90%\",height:\"75%\"}",
       series="[{color:'green'},
                     {color: 'red'}]"
  )}


interact_table <- function(data){
  paste0("<table class='tg'><tr><th class='tg-yw4l'></th><th class='tg-yw4l'>Freshmen</th><th class='tg-yw4l'>Seniors</th></tr><tr><td class='tg-label'>PCOE</td><td class='tg-data'>", data[6],"</td><td class='tg-data'>",data[7],"</td></tr><tr><td class='tg-label'>OHIO U</td><td class='tg-data'>",data[5],"</td><td class='tg-data'>",data[4],"</td></tr></table>")
}                    


target <- function(header,target,object,object2,id=c("enrollment","fundamentals","clinicalmodel","econimpact")){
  paste0("<div class='modal fade' id='",target,"'role='dialog'><div class='modal-dialog modal-lg'>","<div class='modal-content'><div class='modal-header' id='",id,"'><button type='button' class='close' data-dismiss='modal'>&times;</button>",header,"</div><div class='modal-body'",object,object2,"</div></div></div>")
  }


my_tabBox <- function(...){tabBox(...)}



# Data containers ---------------------------------------------------------


reten <- selector("First-year Retention")
grate <- selector("Six-Year Graduation")

degree <- selector("Degrees Granted")
degree <- degree %>% select(-c(Category,Subcategory, Benchmark))
degree <- degree[order(degree$Year,decreasing = T),]
degree$Year <- as.character(degree$Year)

act <- selector("ACT Composite")
ratio <- selector("Student-Faculty Ratio")
faculty <- selector("Group I Faculty")
credit <- selector("Annual WSCH")
grants <- selector("Grants and Contracts (Awarded)")
expenses <- selector("Clinical Expenses")
trips <- selector("Student Travel (Trips)")
student_funding <- selector("Student Travel (Amount)")

interact <- data %>% filter(Subcategory == "Student-Faculty Interaction") %>% spread(Type, Value)

undergraduate <- selector("Undergraduate Headcount") %>% select(-c(Category,Subcategory, Benchmark))
graduate <- selector("Graduate Headcount") %>% select(-c(Category,Subcategory, Benchmark))

diversity <- selector("Student Diversity - College")
diversity$College <- round(diversity$College,1)
diversity$Benchmark <- round(diversity$Benchmark,1)

diversity_under <- selector("Student Diversity - Undergraduate")%>% select(-c(Category,Subcategory))
diversity_grad <- selector("Student Diversity - Graduate") %>% select(-c(Category,Subcategory))

gift <- data %>% filter(Subcategory =="Gifts (Pledges)")

districts <- selector("Number of School District Partners")
partners <- selector("Number of Higher Education Partners")
candidates <- selector("Early Field Candidates Engaged in Experiential Learning in Schools")
hours <- selector("Average Hours Early Field Candidates Engage in Experiential Learning in Schools")
candidates_interns <- selector("Professional Interns Candidates Impacting Student Learning")
hours_interns <- selector("Average Hours Professional Interns Spend Impacting Student Learning")

econ_teachers <-selector("Minimum Economic Impact of Preservice Teachers in Ohio") 
econ_students <-selector("Percent of PCOE Sudents Who Graduated & Employed in Education - Advanced Degrees") 
econ_students_undergrad <-selector("Percent of PCOE Sudents Who Graduated & Employed in Education - Undergraduates") 
econ_students_grad <- selector("Percent of PCOE Students Who Graduated & Returned to School")
alumni_world <- selector("Number of PCOE Alumni Worldwide")
alumni_oh <- selector("Number of PCOE Alumni in Ohio")


# Header ----------------------------------------------------------


header <- dashboardHeader(title=HTML("<p class='dashboard'>Dashboard <i class='fa fa-graduation-cap'></i> </p>"),
                          dropdownMenu(type = "notifications",  icon=icon("envelope-o"),notificationItem(
                            text = "Dashboard updated on 6/12/2016.",
                            icon = icon("life-ring")
                            )
                          ))

# Sidebar -----------------------------------------------------------------


sidebar <- dashboardSidebar(sidebarMenu(
  id="tabs",
                                
  menuItem("About", icon=icon("home"), tabName="about"),                                                
  menuItem("Four Fundamentals", tabName = "fundamentals", icon=icon("bank")),
  menuItem("Enrollment", tabName = "enrollment", icon=icon("graduation-cap")), 
  menuItem("Capital Campaign", tabName = "campaign", icon=icon("money")),
  menuItem("Clinical Model", tabName = "teacherprep", icon=icon("users")),
  menuItem("Economic Impact", tabName = "econimpact", icon=icon("line-chart")),

  menuItem("Teacher Education",tabName="teacher_ed", icon = icon("dashboard")),
  menuItem("Data Notes", tabName="datanotes",icon=icon("hand-o-right")),
           HTML("<br><br><div class=ou><img src='white_trans.png' width=83%></div>")
           
 )
)


# Body --------------------------------------------------------------------



body <- dashboardBody(tags$head(
  tags$script(src = "custom.js"),
  tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")),
  
  tabItems( 
    tabItem(tabName="about",
    fluidRow(fluidRow(width = 12,
      HTML("<div class='jumbotron'>
    <div class='container'>
        <h1 style=color:#fff>Welcome to The Patton College of Education Dashboard </h1> <br>
        <p style=color:#fff><span class='highlight highlight--wrapping' >This page contains the most important and the most up-to-date information about key metrics and performance indicators for our college.  All indicators are grouped in five different categories. Below is a short description.</p></span>
      </div>
</div>
           ")),
      
      HTML(
        
        "<div class='container colorless'>
          <div class='row'>
          <div class='col-md-4'>
          <h2>OHIO's Four Fundamentals</h2>
          <p style=line-height:1.7>These indicators are based on the Ohio University's vision of becoming the nation's best learning community. The four fundamentals include: 
<ul>
<li>Inspired teaching and research</li>
<li>Innovative academic programs</li>
<li>Exemplary student support services</li>
<li>Integrated co-curricular activities</li.
</ul>
</p>
          </div>
          <div class='col-md-4'>
          <h2>Enrollment</h2>
          <p style=line-height:1.7>As our nation is changing demographically, we believe that higher education should reflect this growth and diversity. These indicators help us measure student enrollment and student diversity in our College. They also help us stay competitive and provide better ways to support our students. </p>
          
          </div>
          <div class='col-md-4'>
          <h2>Capital Campaign</h2>
          <p style=line-height:1.7>Our alumni share a pride in The Patton College and in Ohio University. The margin of excellence that underlies this pride is made possible by the generous private support of alumni and friends. We work continually to enhance the educational experience for all our students and this is made possible by alumni support.</p>
          
          </div>
          </div>
          
         <div class='row'>
        <div class='col-md-4'>
          <h2>PCOE Clinical Model</h2>
          <p style=line-height:1.7>Ohio University’s Patton College of Education has a strong tradition of being a leader in innovation in teacher education. Our new Clinical Model is an affirmation of our belief that teaching is learned best through doing. </p>
      </div>
        <div class='col-md-4'>
          <h2>Economic Impact</h2>
          <p style=line-height:1.7>These indicators show the economic contribution of our College and our students. They demonstrate that we are a generator and driver of economic growth in the region and beyond.</p>
         
       </div>
        
      </div>
          <hr>
          <footer>
          <p>© Patton College 2016</p>
          </footer>
          </div>"
        
        
      )
      
     )),  
    


# Four-Fundamenals First row ----------------------------------------------------------------


tabItem(tabName ="fundamentals" ,
        

 fluidRow(
    my_tabBox(title="Retention Rate",width=4,id="fundamentals",
              tabPanel(title = "Current Status", HTML(latest_val(reten, target="retention",type= "percent",subtitle = "Percent of freshman who return for a second year"), target(header="Retention Rate",id="fundamentals",target="retention",popup_val(reten,"percent",subtitle="Percent of freshman who return for a second year"),htmlOutput("popup_retention")))),
              tabPanel(title = "Trend", htmlOutput('retention')))
     ,
    
    my_tabBox(title="Graduation Rate",width = 4,id="fundamentals",
               tabPanel(title = "Current Status", HTML(latest_val(grate,target="grate",type="percent",subtitle = "Percentage of freshman graduating within six years"),target(header="Graduation Rate", id="fundamentals", target="grate",popup_val(grate,"percent",subtitle="Percentage of freshman graduation within six years"),htmlOutput("popup_grate")))),
               tabPanel(title = "Trend", htmlOutput('grate')))
     ,
     
    my_tabBox(title="Degrees Granted",width = 4, id="fundamentals",
    tabPanel(title = "Current Status", HTML(latest_val(degree,target="degree",type="value",subtitle="Total number (annual) of undegraduate degrees awarded"),target(header="Degrees Granted", id="fundamentals",target='degree', popup_val(degree,"value",subtitle="Total number of undergraduate degrees awarded"),htmlOutput('popup_degree')))),
    tabPanel(title = "Trend", htmlOutput('degree'))
    )
    )
 , 

# Four-Fundamenals Second row --------------------------------------------------------------


   fluidRow(
     my_tabBox(title="ACT Composite Score", width=4, id="fundamentals",
               tabPanel(title = "Current Status", HTML(latest_val(act,target="act",type="value",subtitle="Mean composite ACT score for freshman"),target(header="ACT Composite Score",id="fundamentals",target="act",popup_val(act,type="value", subtitle="Mean composite ACT score for freshman"),htmlOutput("popup_act")))),
               tabPanel(title = "Trend", htmlOutput('act')))
     ,

     my_tabBox(title="Student-Faculty Ratio",width = 4,id="fundamentals",
               tabPanel(title = "Current Status", HTML(latest_val(ratio,target="ratio",type="ratio",subtitle = "Undegraduate and Graduate FTE to faculty"),target(header="Student-Faculty Ratio", id="fundamentals",target="ratio",popup_val(ratio,type="ratio",subtitle = "Undergraduate and Graduate FTE to faculty"), htmlOutput("popup_ratio")))),
               tabPanel(title = "Trend", htmlOutput('ratio'))    
     )
     ,
     
     my_tabBox(title="Student Interaction", width = 4,id="fundamentals",
       tabPanel(title="Current Status", HTML(interact_table(interact))),        
       tabPanel(title="More", includeMarkdown("www/interaction.md"))
     )
     )
,
 
 
# Four-Fundamenals Third row ---------------------------------------------------------------
 
 
 
 fluidRow(
   my_tabBox(title="Group I Faculty", width=4,id="fundamentals",
             tabPanel(title = "Current Status", HTML(latest_val(faculty,target="faculty",type="percent",subtitle="Percent of full-time tenured faculty"),target(header="Group I Faculty", id="fundamentals",target="faculty",popup_val(faculty,type="percent",subtitle = "Percent of full-time tenured faculty"), htmlOutput('popup_faculty')))),
             tabPanel(title = "Trend", htmlOutput('faculty')))
     ,
   
   my_tabBox(title="WSCH", width = 4,id="fundamentals",
             tabPanel(title = "Current Status", HTML(latest_val(credit, target="credit",type="value", subtitle="Weighted Student Credit Hours"),target(header="Credit Hours", id="fundamentals",target="credit", popup_val(credit,type="value",subtitle="Weighted student credit hours"), htmlOutput('popup_credit')))),
             tabPanel(title = "Trend", htmlOutput('credit'))    
   )
   ,
   
   my_tabBox(title="Grants & Contracts",width = 4,id="fundamentals",
             tabPanel(title = "Current Status", HTML(latest_val(grants,target="grants",type="dollar",subtitle="Funding amount received"),target(header="Grants & Contracts", id="fundamentals",target="grants", popup_val(grants, type="dollar",subtitle = "Funding amount received"),htmlOutput("popup_grants")))),
             tabPanel(title = "Trend", htmlOutput('grants'))
   
   )
   )
   
 ,
 
 
# Four-Fundamenals Fourth row --------------------------------------------------------------
 
 
 fluidRow(
   my_tabBox(title="Clinical Expenses", width=4,id="fundamentals",
             tabPanel(title = "Current Status", HTML(latest_val(expenses,target="expenses",type="dollar",subtitle="Clinical Expenses in Teacher Education"),target(header="Clinical Expenses", id="fundamentals",target="expenses", popup_val(expenses,type="dollar", subtitle="Clinical Expenses in Teacher Education"), htmlOutput('popup_expenses')))),
             tabPanel(title = "Trend", htmlOutput('expenses')))
   ,
 
   my_tabBox(title="Student Travel",width = 4,id="fundamentals",
             tabPanel(title = "Current Status", HTML(latest_val(trips, target="trips",type ="value",subtitle="Number of students awarded travel"),target(header="Student Travel", id="fundamentals",target="trips",popup_val(trips,type="value",subtitle = "Travel grants awarded to students"),htmlOutput('popup_trips')))),
             tabPanel(title = "Trend", htmlOutput('trips')))
  ,
 
   my_tabBox(title="Student Travel",width = 4,id="fundamentals",
             tabPanel(title = "Current Status", HTML(latest_val(student_funding,target ="student_funding",type = "dollar",subtitle="Travel funding awarded to students"),target(header="Student Travel",id="fundamentals", target="student_funding",popup_val(student_funding,type="dollar",subtitle = "Travel funding awarded to students"), htmlOutput("popup_student_funding")))),
             tabPanel(title = "Trend", htmlOutput('student_funding')))
   ))

   ,
 
# Enrollment  ----------------------------------------------------------
 
 tabItem(tabName = 'enrollment',
         
         fluidRow(
           my_tabBox(title="Undergraduate Enrollment", width=4,id="enrollment",
                     tabPanel(title = "Current Status", HTML(latest_val(undergraduate,target="undergraduate",type="value",subtitle="Main campus headcount, fall term"),target(header="Undergraduate Enrollment", id="enrollment",target="undergraduate",popup_val(undergraduate,type="value",subtitle="Main campus headcount, fall term"),htmlOutput("popup_undergraduate")))),
                     tabPanel(title = "Trend", htmlOutput('undergraduate')))
           ,
           
           my_tabBox(title="Graduate Enrollment",width = 4,id="enrollment",
                     tabPanel(title = "Current Status", HTML(latest_val(graduate,target="graduate",type="value",subtitle="Main campus headcount, fall term"),target(header="Graduate Enrollment", id="enrollment",target="graduate",popup_val(graduate,type='value',subtitle="Main campus headcount, fall term"), htmlOutput('popup_graduate')))),
                     tabPanel(title = "Trend", htmlOutput('graduate'))    
           ),
           
           my_tabBox(title="Diversity: College",width = 4,id="enrollment",
                     tabPanel(title = "Current Status", HTML(latest_val(diversity,target="diversity",type="percent",subtitle="Percent minority, main campus"),target(header="Diversity: College", id="enrollment",target="diversity",popup_val(diversity,type="percent",subtitle="Percent minority, main campus"),htmlOutput('popup_diversity')))),
                     tabPanel(title = "Trend", htmlOutput('diversity'))
                     
         
         )),
         
         fluidRow(
           my_tabBox(title="Diversity: Undergraduate", width=4, id="enrollment",
             tabPanel(title="Current Status", HTML(latest_val(diversity_under,target="diversity_under",type="percent",subtitle="Percent minority, main campus"),target(header="Diversity: Undergraduate", id="enrollment",target="diversity_under",popup_val(diversity_under,type="percent", subtitle = "Percent minority, main campus"),htmlOutput('popup_diversity_under')))),
             tabPanel(title="Trend", htmlOutput("diversity_under"))
           
             ),
           
           my_tabBox(title="Diversity: Graduate", width=4,id="enrollment",
                       tabPanel(title="Current Status", HTML(latest_val(diversity_grad,target="diversity_grad",type="percent",subtitle="Percent minority, main campus"),target(header="Diversity: Graduate", id="enrollment",target="diversity_grad",popup_val(diversity_grad,type="percent", subtitle = "Percent minority, main campus"),htmlOutput("popup_diversity_grad")))),
                       tabPanel(title="Trend", htmlOutput("diversity_grad"))
                       
 )))
,
 
 
# Capital Campaign --------------------------------------------------------
 
 
 tabItem(tabName ="campaign", fluidRow(
   
   highchartOutput("gifts")
 ))
,
 
# Clinical Model ----------------------------------------------------------
 
 
 tabItem(tabName = "teacherprep", 
         
     fluidRow(
         my_tabBox(title="Clinical Model", width=4, id="clinicalmodel",
                   tabPanel(title = "Current Status",HTML(latest_val(districts,target = "districts",type="value",subtitle="Number of school district partners"),target(header="Clinical Model", id="clinicalmodel",target="districts", popup_val(districts, type="value", subtitle = "Number of school districts partners"),htmlOutput('popup_districts')))),
                   tabPanel(title="Trend",htmlOutput("districts"))),
         
         my_tabBox(title="Clinical Model", width=4, id="clinicalmodel",
                   tabPanel(title = "Current Status", HTML(latest_val(partners, target ="partners", type ="value",subtitle="Number of higher education partners"), target(header="Clinical Model", id="clinicalmodel",target="partners", popup_val(partners, type="value", subtitle = "Number of higher education partners"),htmlOutput('popup_partners')))),
                   tabPanel(title="Trend", htmlOutput("partners"))),
         
         my_tabBox(title="Clinical Model", width=4, id="clinicalmodel",
                   tabPanel(title = "Current Status", HTML(latest_val(candidates,target="candidates",type = "value",subtitle = "Number of Early Field candidates in schools"), target(header="Clinical Model", id="clinicalmodel",target="candidates",popup_val(candidates,type="value",subtitle="Number of Early Field candidates in schools"),htmlOutput('popup_candidates')))),
                   tabPanel(title="Trend", htmlOutput("candidates")))  
         ),
  
        fluidRow(
         my_tabBox(title="Clinical Model", width=4, id="clinicalmodel",
                   tabPanel(title = "Current Status", HTML(latest_val(hours,target ="hours", type = "value",subtitle = "Average number of hours Early Field candidates engage in Experiential Learning"),target(header="Clinical Model", id="clinicalmodel",target = "hours", popup_val(hours,type="value",subtitle = "Average number of hours Early Field candidates engage in Experiential Learning"),htmlOutput('popup_hours')))),
                   tabPanel(title="Trend",htmlOutput("hours"))),
        
          my_tabBox(title="Clinical Model", width=4, id="clinicalmodel",
                   tabPanel(title = "Current Status",HTML(latest_val(candidates_interns, target ="candidates_interns",type ="value", subtitle = "Number of Professional Intern candidates impacting student learning process"),target(header="Clinical Model", id="clinicalmodel",target="candidates_interns",popup_val(candidates_interns,type="value",subtitle = "Number of Professional Intern candidates impacting student learning process"),htmlOutput("popup_candidates_interns")))),
                   tabPanel(title="Trend", htmlOutput("candidates_interns"))),
        
          my_tabBox(title="Clinical Model", width=4,id="clinicalmodel",
                   tabPanel(title = "Current Status",HTML(latest_val(hours_interns,target="hours_interns",type ="value",subtitle = "Average number of hours Professional Interns spend impacting student learning"),target(header="Clinical Model", id="clinicalmodel",target="hours_interns", popup_val(hours_interns,type="value",subtitle="Average number of hours Professional Interns spend impacting student learning"), htmlOutput("popup_hours_interns")))),
                   tabPanel(title="Trend",htmlOutput("hours_interns")))  
       )
 )

,
 

# Economic Impact ---------------------------------------------------------


tabItem(tabName = "econimpact",

        fluidRow(
          my_tabBox(title="Economic Impact", width=4, id="econimpact",
                    tabPanel(title = "Current Status",HTML(latest_val(econ_teachers,target="econ_teachers",type="dollar",subtitle="Minimum economic impact of pre-service teachers in Ohio"),target(header="Economic Impact", id="econimpact",target="econ_teachers", popup_val(econ_teachers,type="dollar",subtitle="Minimum economic impact of pre-service teachers in Ohio"),htmlOutput("popup_econ_teachers")))),
                    tabPanel(title="Trend",htmlOutput("econ_teachers"))),

          my_tabBox(title="Economic Impact", width=4, id="econimpact",
                    tabPanel(title = "Current Status", HTML(latest_val(econ_students,target="econ_students", type="percent", subtitle="PCOE graduates employed in education - Advanced Degrees"),target(header="Economic Impact", id="econimpact",target="econ_students",popup_val(econ_students,type="percent",subtitle = "PCOE graduates employed in education - Advanced Degrees"),htmlOutput('popup_econ_students')))),
                    tabPanel(title="Trend", htmlOutput("econ_students"))),

          my_tabBox(title="Economic Impact", width=4, id="econimpact",
                    tabPanel(title = "Current Status", HTML(latest_val(econ_students_undergrad,target="econ_students_undergrad",type="percent",subtitle="PCOE graduates employed in education - Undergraduates"), target(header="Economics Impact", id="econimpact",target="econ_students_undergrad", popup_val(econ_students_undergrad,type="percent", subtitle = "PCOE graduates employed in education - Undergraduates"),htmlOutput("popup_econ_students_undergrad")))),
                    tabPanel(title="Trend", htmlOutput("econ_students_undergrad")))
        ),

        fluidRow(
          my_tabBox(title="Economic Impact", width=4, id="econimpact",
                    tabPanel(title = "Current Status", HTML(latest_val(econ_students_grad,target="econ_students_grad",type="percent",subtitle="PCOE graduates who returned to College"), target(header = "Economic Impact", id="econimpact",target="econ_students_grad", popup_val(econ_students_grad,type="percent",subtitle="PCOE graduates who returned to College"),htmlOutput("popup_econ_students_grad")))),
                    tabPanel(title="Trend",htmlOutput("econ_students_grad"))),

          
          my_tabBox(title="Economic Impact", width=4,id="econimpact",
                    tabPanel(title = "Current Status",HTML(latest_val(alumni_world, target="alumni_world",type="value",subtitle="Number of PCOE Alumni Worldwide"),target(header="Economic Impact",id="econimpact", target="alumni_world",popup_val(alumni_world,type="value", subtitle="Number of PCOE Alumni Worldwide"),htmlOutput("popup_alumni_world")))),
                    tabPanel(title="Trend", htmlOutput("alumni_world"))),

          my_tabBox(title="Economic Impact", width=4, id="econimpact",
                    tabPanel(title = "Current Status",HTML(latest_val(alumni_oh,target="alumni_oh",type="value",subtitle="Number of PCOE Alumni in Ohio"),target(header="Economic Impact", id="econimpact",target="alumni_oh", popup_val(alumni_oh,type='value',subtitle="Number of PCOE Alumni in Ohio"),htmlOutput("popup_alumni_oh")))),
                    tabPanel(title="Trend",htmlOutput("alumni_oh")))
        )
),


# Teacher Education Graduates ---------------------------------------------


tabItem(tabName = "teacher_ed",
        box(title="Comparison of the Number of Teacher Education Graduates: 2012-13",
            DT::dataTableOutput('teacher_ed')))

)
)


ui <- dashboardPage(skin="red",header, sidebar, body)




# Server ------------------------------------------------------------------


server <- function(input, output, session) { 
    output$retention <- renderGvis({gvisLineChart(reten,options=additional(50,100))})
    output$popup_retention <- renderGvis({gvisLineChart(reten,options=additional(50,100))})
    
    output$grate <- renderGvis({gvisLineChart(grate,options=additional(30,90))})
    output$popup_grate <- renderGvis({gvisLineChart(grate,options=additional(30,90))})
    
    output$degree <- renderGvis({gvisLineChart(degree,options=additional(30,90))})
    output$popup_degree <- renderGvis({gvisLineChart(degree,options=additional(30,90))})
    
    output$act <- renderGvis({gvisLineChart(act,options=additional(0,30))})
    output$popup_act <- renderGvis({gvisLineChart(act,options=additional(0,30))})
    
    output$ratio <- renderGvis({gvisLineChart(ratio,options=additional(0,30))})
    output$popup_ratio <- renderGvis({gvisLineChart(ratio,options=additional(0,30))})
    
    output$faculty <- renderGvis({gvisLineChart(faculty,options=additional(0,30))})
    output$popup_faculty <- renderGvis({gvisLineChart(faculty,options=additional(0,30))})
    
    output$credit <- renderGvis({gvisLineChart(credit,options=additional(0,200000))})
    output$popup_credit <- renderGvis({gvisLineChart(credit,options=additional(0,200000))})
    
    output$grants <- renderGvis({gvisLineChart(grants,options=additional(0,4000000))})
    output$popup_grants <- renderGvis({gvisLineChart(grants,options=additional(0,4000000))})
    
    output$expenses <- renderGvis({gvisLineChart(expenses,options=additional(0,750000))})
    output$popup_expenses <- renderGvis({gvisLineChart(expenses,options=additional(0,750000))})
    
    output$trips <- renderGvis({gvisLineChart(trips,options=additional(0,65))})
    output$popup_trips <- renderGvis({gvisLineChart(trips,options=additional(0,65))})
    
    output$student_funding <-renderGvis({gvisLineChart(student_funding,options=additional(0,25000))}) 
    output$popup_student_funding <-renderGvis({gvisLineChart(student_funding,options=additional(0,25000))}) 
    
    
    output$undergraduate <-  renderGvis({gvisLineChart(undergraduate,options=additional(0,2300))})
    output$popup_undergraduate <-  renderGvis({gvisLineChart(undergraduate,options=additional(0,2300))})
    
    
    output$graduate <-  renderGvis({gvisLineChart(graduate,options=additional(0,1200))})
    output$popup_graduate <-  renderGvis({gvisLineChart(graduate,options=additional(0,1200))})
    
    output$diversity <- renderGvis({gvisLineChart(diversity,options=additional(0,40))})
    output$popup_diversity <- renderGvis({gvisLineChart(diversity,options=additional(0,40))})
    
    output$diversity_under <-renderGvis({gvisLineChart(diversity_under,options=additional(0,40))})
    output$popup_diversity_under <-renderGvis({gvisLineChart(diversity_under,options=additional(0,40))})
    
    output$diversity_grad <-renderGvis({gvisLineChart(diversity_grad,options=additional(0,40))})
    output$popup_diversity_grad <-renderGvis({gvisLineChart(diversity_grad,options=additional(0,40))})
    
    
    output$gifts <- renderHighchart({
      highchart() %>%
      hc_xAxis(categories = gift$Year) %>% 
      hc_add_series(name = "College", data = gift$Value) %>% 
      hc_title(text="Total Amount of Gifts and Pledges") %>% 
      hc_exporting(enabled = TRUE)
 
      
      
    }) 
    
    output$candidates <- renderGvis({gvisLineChart(candidates,options=additional(0,2000))})
    output$popup_candidates <- renderGvis({gvisLineChart(candidates,options=additional(0,2000))})
    
    output$candidates_interns <- renderGvis({gvisLineChart(candidates_interns,options=additional(0,600))})
    output$popup_candidates_interns <- renderGvis({gvisLineChart(candidates_interns,options=additional(0,600))})
    
    output$districts <- renderGvis({gvisColumnChart(districts,options=additional(0,200))})
    output$popup_districts <- renderGvis({gvisColumnChart(districts,options=additional(0,200))})
    
    output$hours <- renderGvis({gvisColumnChart(hours,options=additional(0,200))})
    output$popup_hours <- renderGvis({gvisColumnChart(hours,options=additional(0,200))})
    
    output$hours_interns <- renderGvis({gvisColumnChart(hours_interns,options=additional(0,700))})
    output$popup_hours_interns <- renderGvis({gvisColumnChart(hours_interns,options=additional(0,700))})
    
    output$partners <- renderGvis({gvisColumnChart(partners,options=additional(0,10))})
    output$popup_partners <- renderGvis({gvisColumnChart(partners,options=additional(0,10))})
    
    output$alumni_oh <- renderGvis({gvisColumnChart(alumni_oh,options=additional(0,35000))})
    output$alumni_world <- renderGvis({gvisColumnChart(alumni_world,options=additional(0,45000))})
    output$econ_students <- renderGvis({gvisColumnChart(econ_students,options=additional(0,100))})
    output$econ_students_grad <- renderGvis({gvisColumnChart(econ_students_grad,options=additional(0,10))})
    output$econ_students_undergrad <- renderGvis({gvisColumnChart(econ_students_undergrad,options=additional(0,100))})
    output$econ_teachers <- renderGvis({gvisLineChart(econ_teachers,options=additional(0,12000000))})
    
    
    output$popup_alumni_oh <- renderGvis({gvisColumnChart(alumni_oh,options=additional(0,35000))})
    output$popup_alumni_world <- renderGvis({gvisColumnChart(alumni_world,options=additional(0,45000))})
    output$popup_econ_students <- renderGvis({gvisColumnChart(econ_students,options=additional(0,100))})
    output$popup_econ_students_grad <- renderGvis({gvisColumnChart(econ_students_grad,options=additional(0,10))})
    output$popup_econ_students_undergrad <- renderGvis({gvisColumnChart(econ_students_undergrad,options=additional(0,100))})
    output$popup_econ_teachers <- renderGvis({gvisLineChart(econ_teachers,options=additional(0,12000000))})
    
    
    output$teacher_ed <-DT::renderDataTable({datatable(teacher_ed,options=list(bFilter=F, pageLength = 7))}) 
         }

shinyApp(ui, server)
