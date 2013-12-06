# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Policy.create({ title: "Collaboration Permitted in Written Work", is_public: true, 
    text: "Discussion and the exchange of ideas are essential to academic work. For assignments in this course, you are encouraged to consult with your classmates on the choice of paper topics and to share sources. You may find it useful to discuss your chosen topic with your peers, particularly if you are working on the same topic as a classmate. However, you should ensure that any written work you submit for evaluation is the result of your own research and writing and that it reflects your own approach to the topic. You must also adhere to standard citation practices in this discipline and properly cite any books, articles, websites, lectures, etc. that have helped you with your work. If you received any help with your writing (feedback on drafts, etc), you must also acknowledge this assistance."})
Policy.create({ title: "Collaboration Permitted in Problem Sets", is_public: true, 
    text: "Discussion and the exchange of ideas are essential to doing academic work. For assignments in this course, you are encouraged to consult with your classmates as you work on problem sets. However, after discussions with peers, make sure that you can work through the problem yourself and ensure that any answers you submit for evaluation are the result of your own efforts. In addition, you must cite any books, articles, websites, lectures, etc that have helped you with your work using appropriate citation practices. Similarly, you must list the names of students with whom you have collaborated on problem sets."})
Policy.create({ title: "Collaboration Prohibited", is_public: true, 
    text: "Students should be aware that in this course collaboration of any sort on any work submitted for formal evaluation is not permitted. This means that you may not discuss your problem sets, paper assignments, exams, or any other assignments with other students. All work should be entirely your own and must use appropriate citation practices to acknowledge the use of books, articles, websites, lectures, discussions, etc., that you have consulted to complete your assignments."})
